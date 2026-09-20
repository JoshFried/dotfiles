use std::{fs, path::Path};

use assert_cmd::{Command, cargo::cargo_bin_cmd};
use predicates::prelude::*;
use tempfile::TempDir;

struct Fixture {
    repo: TempDir,
    home: TempDir,
}

impl Fixture {
    fn new(destination_exists: bool) -> Self {
        let repo = tempfile::tempdir().unwrap();
        let home = tempfile::tempdir().unwrap();
        fs::write(repo.path().join("source"), "desired").unwrap();
        if destination_exists {
            std::os::unix::fs::symlink(repo.path().join("source"), home.path().join("destination"))
                .unwrap();
        }
        fs::write(
            repo.path().join("dotfiles.toml"),
            r#"
            version = 1
            default_profiles = ["test"]
            [profiles]
            test = ["symlink.test"]
            [[resources]]
            id = "symlink.test"
            description = "Test symlink"
            kind = "symlink"
            source = "source"
            destination = "~/destination"
            "#,
        )
        .unwrap();
        Self { repo, home }
    }

    fn command(&self) -> Command {
        let mut command = cargo_bin_cmd!("dotfiles");
        command
            .arg("--repo")
            .arg(self.repo.path())
            .env("HOME", self.home.path());
        command
    }

    fn destination(&self) -> &Path {
        self.home.path()
    }
}

#[test]
fn help_is_generated_by_clap_derive() {
    cargo_bin_cmd!("dotfiles")
        .arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "Audit, understand, and apply this machine's dotfiles",
        ))
        .stdout(predicate::str::contains("COMMANDS:"))
        .stdout(predicate::str::contains("GLOBAL OPTIONS:"))
        .stdout(predicate::str::contains("Examples:"));
}

#[test]
fn unknown_subcommands_fail_with_usage() {
    cargo_bin_cmd!("dotfiles")
        .arg("destroy")
        .assert()
        .failure()
        .stderr(predicate::str::contains("Usage:"));
}

#[test]
fn audit_returns_success_for_healthy_resources() {
    let fixture = Fixture::new(true);
    fixture
        .command()
        .args(["audit", "--json"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"status\": \"healthy\""));
}

#[test]
fn audit_returns_drift_exit_code_for_missing_resources() {
    let fixture = Fixture::new(false);
    fixture
        .command()
        .args(["audit", "--json"])
        .assert()
        .code(1)
        .stdout(predicate::str::contains("\"status\": \"missing\""));
}

#[test]
fn plan_reports_only_required_changes() {
    let fixture = Fixture::new(false);
    fixture
        .command()
        .arg("plan")
        .assert()
        .success()
        .stdout(predicate::str::contains("link ~/destination"));
}

#[test]
fn apply_creates_the_selected_symlink() {
    let fixture = Fixture::new(false);
    fixture
        .command()
        .args(["apply", "--yes"])
        .assert()
        .success()
        .stdout(predicate::str::contains("OK symlink.test"));
    assert_eq!(
        fs::read_link(fixture.destination().join("destination"))
            .unwrap()
            .canonicalize()
            .unwrap(),
        fixture.repo.path().join("source").canonicalize().unwrap()
    );
}

#[test]
fn every_run_writes_structured_verbose_logs() {
    let fixture = Fixture::new(false);
    let logs = tempfile::tempdir().unwrap();
    fixture
        .command()
        .arg("--log-directory")
        .arg(logs.path())
        .args(["audit", "--json"])
        .assert()
        .code(1);

    let contents = fs::read_dir(logs.path())
        .unwrap()
        .map(|entry| fs::read_to_string(entry.unwrap().path()).unwrap())
        .collect::<String>();
    let events: Vec<serde_json::Value> = contents
        .lines()
        .map(|line| serde_json::from_str(line).unwrap())
        .collect();

    assert!(events.iter().any(|event| {
        event["message"] == "dotfiles run started" && event["run_id"].is_string()
    }));
    assert!(events.iter().any(|event| {
        event["message"] == "resource audited"
            && event["resource_id"] == "symlink.test"
            && event["status"] == "missing"
    }));
    assert!(
        events
            .iter()
            .any(|event| event["message"] == "audit completed" && event["issue_count"] == 1)
    );
}

#[test]
fn verbose_mode_writes_diagnostics_to_stderr_only() {
    let fixture = Fixture::new(true);
    fixture
        .command()
        .args(["-v", "audit"])
        .assert()
        .success()
        .stdout(predicate::str::contains("1 healthy"))
        .stderr(predicate::str::contains("dotfiles run started"));
}

#[test]
fn forced_color_highlights_human_readable_audit_output() {
    let fixture = Fixture::new(false);
    fixture
        .command()
        .env_remove("NO_COLOR")
        .env("CLICOLOR_FORCE", "1")
        .arg("audit")
        .assert()
        .code(1)
        .stdout(predicate::str::contains("\u{1b}["))
        .stdout(predicate::str::contains("missing"))
        .stdout(predicate::str::contains("symlink.test"));
}

#[test]
fn json_output_never_contains_terminal_color_sequences() {
    let fixture = Fixture::new(false);
    fixture
        .command()
        .env("CLICOLOR_FORCE", "1")
        .args(["audit", "--json"])
        .assert()
        .code(1)
        .stdout(predicate::str::contains("\"status\": \"missing\""))
        .stdout(predicate::str::contains("\u{1b}[").not());
}

#[test]
fn no_color_disables_human_readable_output_colors() {
    let fixture = Fixture::new(false);
    fixture
        .command()
        .env("CLICOLOR_FORCE", "1")
        .env("NO_COLOR", "1")
        .arg("audit")
        .assert()
        .code(1)
        .stdout(predicate::str::contains("\u{1b}[").not());
}
