//! Persistent trace-level JSON logging with optional terminal diagnostics.

use std::{
    env, fs,
    io::IsTerminal,
    path::{Path, PathBuf},
    process,
    time::{SystemTime, UNIX_EPOCH},
};

use anyhow::{Context, Result};
use tracing::level_filters::LevelFilter;
use tracing_appender::non_blocking::WorkerGuard;
use tracing_appender::rolling::{RollingFileAppender, Rotation};
use tracing_subscriber::{
    Layer, filter::Targets, fmt, layer::SubscriberExt, util::SubscriberInitExt,
};

use crate::cli::{Cli, Command};

/// Keeps the non-blocking log writer alive for one application run.
pub struct LoggingGuard {
    _file_guard: WorkerGuard,
    /// Directory containing the rolling JSONL log.
    pub directory: PathBuf,
    /// Timestamp-and-process identifier attached to lifecycle events.
    pub run_id: String,
}

/// Installs file and optional terminal tracing subscribers.
///
/// TUI invocations suppress terminal logs to protect the alternate screen.
///
/// # Errors
///
/// Returns an error when the log directory cannot be created or a global
/// tracing subscriber has already been installed.
pub fn init(cli: &Cli) -> Result<LoggingGuard> {
    let directory = cli
        .log_directory
        .clone()
        .unwrap_or_else(default_log_directory);
    fs::create_dir_all(&directory)
        .with_context(|| format!("failed to create log directory {}", directory.display()))?;

    let run_id = run_id();
    let appender = RollingFileAppender::builder()
        .rotation(Rotation::DAILY)
        .filename_prefix("dotfiles.jsonl")
        .build(&directory)
        .with_context(|| {
            format!(
                "failed to initialize rolling log file in {}",
                directory.display()
            )
        })?;
    let (file_writer, file_guard) = tracing_appender::non_blocking(appender);
    let file_targets = Targets::new()
        .with_target("dotfiles_cli", LevelFilter::TRACE)
        .with_target("dotfiles", LevelFilter::TRACE);

    let file_layer = fmt::layer()
        .json()
        .flatten_event(true)
        .with_ansi(false)
        .with_current_span(true)
        .with_span_list(true)
        .with_target(true)
        .with_writer(file_writer)
        .with_filter(file_targets);

    let terminal_layer = (!is_tui(cli)).then(|| {
        let level = terminal_level(cli.verbose);
        fmt::layer()
            .compact()
            .with_ansi(terminal_color_enabled())
            .with_target(false)
            .with_writer(std::io::stderr)
            .with_filter(
                Targets::new()
                    .with_target("dotfiles_cli", level)
                    .with_target("dotfiles", level),
            )
    });

    tracing_subscriber::registry()
        .with(file_layer)
        .with(terminal_layer)
        .try_init()
        .context("failed to initialize logging")?;

    tracing::info!(
        run_id,
        version = env!("CARGO_PKG_VERSION"),
        command = ?cli.command,
        verbosity = cli.verbose,
        log_directory = %directory.display(),
        "dotfiles run started"
    );

    Ok(LoggingGuard {
        _file_guard: file_guard,
        directory,
        run_id,
    })
}

fn terminal_level(verbosity: u8) -> LevelFilter {
    match verbosity {
        0 => LevelFilter::WARN,
        1 => LevelFilter::INFO,
        2 => LevelFilter::DEBUG,
        _ => LevelFilter::TRACE,
    }
}

fn is_tui(cli: &Cli) -> bool {
    matches!(cli.command, None | Some(Command::Tui(_)))
}

fn terminal_color_enabled() -> bool {
    if env::var_os("NO_COLOR").is_some() {
        return false;
    }
    let forced = ["CLICOLOR_FORCE", "FORCE_COLOR"]
        .iter()
        .filter_map(|name| env::var(name).ok())
        .any(|value| !value.is_empty() && value != "0");
    forced
        || (std::io::stderr().is_terminal() && !env::var("TERM").is_ok_and(|term| term == "dumb"))
}

fn default_log_directory() -> PathBuf {
    env::var_os("HOME").map_or_else(
        || Path::new(".").join(".dotfiles-logs"),
        |home| PathBuf::from(home).join(".local/state/dotfiles/logs"),
    )
}

fn run_id() -> String {
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    format!("{timestamp}-{}", process::id())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn verbosity_maps_to_expected_terminal_levels() {
        assert_eq!(terminal_level(0), LevelFilter::WARN);
        assert_eq!(terminal_level(1), LevelFilter::INFO);
        assert_eq!(terminal_level(2), LevelFilter::DEBUG);
        assert_eq!(terminal_level(3), LevelFilter::TRACE);
        assert_eq!(terminal_level(u8::MAX), LevelFilter::TRACE);
    }

    #[test]
    fn run_ids_include_process_identity() {
        assert!(run_id().ends_with(&format!("-{}", process::id())));
    }
}
