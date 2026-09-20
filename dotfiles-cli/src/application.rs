use std::{
    env,
    io::{self, Write},
};

use anyhow::{Context, Result};

use crate::{
    cli::{Cli, Command, FilterArgs},
    config::Config,
    console::Console,
    domain::ResourceExplanation,
    engine::Engine,
    logging, tui,
};

pub fn run(cli: Cli) -> Result<u8> {
    let logging = logging::init(&cli)?;
    let result = run_logged(cli);
    match &result {
        Ok(code) => tracing::info!(
            run_id = logging.run_id,
            exit_code = code,
            log_directory = %logging.directory.display(),
            "dotfiles run completed"
        ),
        Err(error) => tracing::error!(
            run_id = logging.run_id,
            error = %format!("{error:#}"),
            log_directory = %logging.directory.display(),
            "dotfiles run failed"
        ),
    }
    result
}

fn run_logged(cli: Cli) -> Result<u8> {
    let repo = cli
        .repo
        .unwrap_or(env::current_dir().context("failed to determine current directory")?);
    let repo = repo
        .canonicalize()
        .with_context(|| format!("repository does not exist: {}", repo.display()))?;
    let config_path = cli.config.unwrap_or_else(|| repo.join("dotfiles.toml"));
    tracing::debug!(repo = %repo.display(), config = %config_path.display(), "resolved runtime paths");
    let engine = Engine::new(Config::load(&config_path)?, repo)?;
    let console = Console::detect();

    execute(cli.command, &engine, &console)
}

fn execute(command: Option<Command>, engine: &Engine, console: &Console) -> Result<u8> {
    match command.unwrap_or(Command::Tui(FilterArgs::default())) {
        Command::Tui(filter) => {
            let selected = engine.select(&filter)?;
            tracing::info!(resource_count = selected.len(), "opening TUI");
            tui::run(engine, selected, *console)?;
            Ok(0)
        }
        Command::Audit { filter, json } => audit(engine, &filter, json, console),
        Command::Plan(filter) => {
            let changes = engine.plan_ids(&engine.select(&filter)?);
            tracing::info!(change_count = changes.len(), "plan generated");
            if changes.is_empty() {
                println!("{}", console.success("No automatic changes are needed."));
            } else {
                for (index, change) in changes.iter().enumerate() {
                    println!(
                        "{} {} — {}",
                        console.detail(format!("{}.", index + 1)),
                        console.identity(&change.id),
                        console.planned_action(&change.action)
                    );
                }
                println!(
                    "\n{}",
                    console.warning(format!("{} change(s) planned.", changes.len()))
                );
            }
            Ok(0)
        }
        Command::Apply { filter, yes } => apply(engine, &filter, yes, console),
        Command::List => {
            tracing::debug!(
                profile_count = engine.config.profiles.len(),
                resource_count = engine.config.resources.len(),
                "listing configuration"
            );
            println!("{}", console.identity("Profiles"));
            for (name, ids) in &engine.config.profiles {
                println!(
                    "  {:16} {}",
                    console.identity(format!("{name:16}")),
                    console.detail(format!("{} resources", ids.len()))
                );
            }
            println!("\n{}", console.identity("Resources"));
            for resource in &engine.config.resources {
                println!(
                    "  {:32} {}",
                    console.identity(format!("{:32}", resource.id)),
                    resource.description
                );
            }
            Ok(0)
        }
        Command::Explain { id } => {
            print_explanation(&engine.explain(&id)?, console);
            Ok(0)
        }
    }
}

fn audit(engine: &Engine, filter: &FilterArgs, json: bool, console: &Console) -> Result<u8> {
    let results = engine.audit_ids(&engine.select(filter)?);
    let issue_count = results
        .iter()
        .filter(|result| !result.status.is_healthy())
        .count();
    tracing::info!(
        resource_count = results.len(),
        issue_count,
        json,
        "audit completed"
    );
    if json {
        println!("{}", serde_json::to_string_pretty(&results)?);
    } else {
        for result in &results {
            println!(
                "{} {:32} {}",
                console.status(
                    result.status,
                    format!("{} {:10}", result.status.symbol(), result.status)
                ),
                console.identity(format!("{:32}", result.id)),
                result.summary
            );
        }
        let healthy = results
            .iter()
            .filter(|result| result.status.is_healthy())
            .count();
        let issues = results.len().saturating_sub(healthy);
        let summary = format!("{healthy} healthy, {issues} issue(s)");
        println!(
            "\n{}",
            if issues == 0 {
                console.success(summary)
            } else {
                console.error(summary)
            }
        );
    }
    Ok(u8::from(
        results.iter().any(|result| !result.status.is_healthy()),
    ))
}

fn apply(engine: &Engine, filter: &FilterArgs, yes: bool, console: &Console) -> Result<u8> {
    let changes = engine.plan_ids(&engine.select(filter)?);
    tracing::info!(
        change_count = changes.len(),
        auto_confirm = yes,
        "apply requested"
    );
    if changes.is_empty() {
        println!("{}", console.success("No automatic changes are needed."));
        return Ok(0);
    }
    for (index, change) in changes.iter().enumerate() {
        println!(
            "{} {} — {}",
            console.detail(format!("{}.", index + 1)),
            console.identity(&change.id),
            console.planned_action(&change.action)
        );
    }
    if !yes
        && !confirm(&format!(
            "\n{}",
            console.warning(format!("Apply {} change(s)?", changes.len()))
        ))?
    {
        tracing::warn!("apply cancelled by user");
        println!("{}", console.warning("Cancelled."));
        return Ok(0);
    }

    let change_ids: Vec<_> = changes.iter().map(|change| change.id.clone()).collect();
    let outcomes = engine.apply_ids(&change_ids, |message| {
        println!("{}", console.detail(message))
    });
    let mut failed = false;
    for (id, outcome) in outcomes {
        match outcome {
            Ok(()) => println!("{} {}", console.success("OK"), console.identity(id)),
            Err(error) => {
                failed = true;
                tracing::error!(resource_id = id, error = %format!("{error:#}"), "resource apply failed");
                eprintln!(
                    "{} {}: {error:#}",
                    console.error("FAIL"),
                    console.identity(id)
                );
            }
        }
    }
    Ok(u8::from(failed))
}

fn print_explanation(explanation: &ResourceExplanation, console: &Console) {
    println!("{}", console.identity(&explanation.id));
    println!("\n{}", explanation.description);
    println!(
        "\n{} {}",
        console.detail("Tags:"),
        display_list(&explanation.tags, console)
    );
    println!(
        "{} {}",
        console.detail("Depends on:"),
        display_list(&explanation.dependencies, console)
    );
    println!(
        "{} {}",
        console.detail("Used by:"),
        display_list(&explanation.dependents, console)
    );
}

fn display_list(values: &[String], console: &Console) -> String {
    if values.is_empty() {
        console.detail("none")
    } else {
        values
            .iter()
            .map(|value| console.identity(value))
            .collect::<Vec<_>>()
            .join(", ")
    }
}

fn confirm(prompt: &str) -> Result<bool> {
    print!("{prompt} [y/N] ");
    io::stdout().flush()?;
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    Ok(matches!(
        input.trim().to_ascii_lowercase().as_str(),
        "y" | "yes"
    ))
}
