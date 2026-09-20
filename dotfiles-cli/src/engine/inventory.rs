//! Homebrew package, formula-alias, service, and executable inventory collection.

use std::{
    collections::{HashMap, HashSet},
    env,
    path::PathBuf,
};

use serde::Deserialize;

use crate::{
    config::ResourceKind,
    system::{CommandRequest, find_program},
};

use super::{Engine, util::package_token};

pub(super) struct Inventory {
    pub brew_available: bool,
    pub formulae: HashSet<String>,
    pub formula_aliases: HashMap<String, String>,
    pub casks: HashSet<String>,
    pub services: HashMap<String, String>,
    pub executables: HashMap<String, PathBuf>,
}

impl Inventory {
    pub fn unavailable() -> Self {
        Self {
            brew_available: false,
            formulae: HashSet::new(),
            formula_aliases: HashMap::new(),
            casks: HashSet::new(),
            services: HashMap::new(),
            executables: HashMap::new(),
        }
    }
}

impl Engine {
    pub(super) fn inventory(&self, ids: &[String]) -> Inventory {
        let started = std::time::Instant::now();
        tracing::debug!("collecting Homebrew inventory");
        if self.brew.is_none() {
            return Inventory::unavailable();
        }

        let formulae = self
            .command_lines(self.brew_request(["list", "--formula"]))
            .into_iter()
            .collect();
        let formula_aliases = self.collect_formula_aliases(ids, &formulae);
        let casks = self
            .command_lines(self.brew_request(["list", "--cask"]))
            .into_iter()
            .collect();
        let service_names: Vec<_> = ids
            .iter()
            .filter_map(|id| self.config.resource(id))
            .filter_map(|resource| match &resource.kind {
                ResourceKind::BrewService { name } => Some(name.clone()),
                _ => None,
            })
            .collect();
        let services = self.collect_services(&service_names);
        let path = env::var_os("PATH");
        let executables = ids
            .iter()
            .filter_map(|id| self.config.resource(id))
            .filter_map(|resource| match &resource.kind {
                ResourceKind::BrewFormula {
                    executable: Some(executable),
                    ..
                } => Some(executable),
                _ => None,
            })
            .filter_map(|executable| {
                find_program(executable, path.as_deref())
                    .map(|location| (executable.clone(), location))
            })
            .collect();

        let inventory = Inventory {
            brew_available: true,
            formulae,
            formula_aliases,
            casks,
            services,
            executables,
        };
        tracing::info!(
            formula_count = inventory.formulae.len(),
            resolved_formula_alias_count = inventory.formula_aliases.len(),
            cask_count = inventory.casks.len(),
            service_count = inventory.services.len(),
            alternate_executable_count = inventory.executables.len(),
            elapsed_ms = started.elapsed().as_millis(),
            "Homebrew inventory collected"
        );
        inventory
    }

    fn collect_formula_aliases(
        &self,
        ids: &[String],
        installed_formulae: &HashSet<String>,
    ) -> HashMap<String, String> {
        ids.iter()
            .filter_map(|id| self.config.resource(id))
            .filter_map(|resource| match &resource.kind {
                ResourceKind::BrewFormula { name, .. } => Some(package_token(name)),
                _ => None,
            })
            .filter(|name| !installed_formulae.contains(*name) && is_major_version_alias(name))
            .filter_map(|name| {
                self.resolve_installed_formula_alias(name)
                    .map(|canonical| (name.to_owned(), canonical))
            })
            .collect()
    }

    fn resolve_installed_formula_alias(&self, name: &str) -> Option<String> {
        let request = self.brew_request(["info", "--json=v2", name]);
        let output = self.runner.capture(&request).ok()?;
        if !output.success {
            tracing::debug!(
                formula = name,
                stderr = output.stderr.trim(),
                "unable to resolve Homebrew formula alias"
            );
            return None;
        }

        let info: BrewInfo = match serde_json::from_str(&output.stdout) {
            Ok(info) => info,
            Err(error) => {
                tracing::warn!(
                    formula = name,
                    error = %error,
                    "unable to parse Homebrew formula metadata"
                );
                return None;
            }
        };
        let formula = info.formulae.into_iter().next()?;
        if formula.installed.is_empty() {
            return None;
        }

        tracing::debug!(
            formula = name,
            canonical_formula = formula.full_name,
            "resolved installed Homebrew formula alias"
        );
        Some(formula.full_name)
    }

    fn collect_services(&self, names: &[String]) -> HashMap<String, String> {
        let request = self.brew_request(["services", "list"]);
        match self.runner.capture(&request) {
            Ok(output) if output.success => {
                let mut services: HashMap<_, _> = output
                    .stdout
                    .lines()
                    .map(str::trim)
                    .filter(|line| !line.is_empty() && !line.starts_with("Name "))
                    .filter_map(parse_service)
                    .collect();
                let missing: Vec<_> = names
                    .iter()
                    .filter(|name| !services.contains_key(name.as_str()))
                    .cloned()
                    .collect();
                if !missing.is_empty() {
                    tracing::debug!(
                        services = ?missing,
                        "brew services inventory omitted configured services; checking launchctl"
                    );
                    services.extend(self.collect_launchctl_services(&missing));
                }
                services
            }
            Ok(output) => {
                tracing::debug!(
                    stderr = output.stderr.trim(),
                    "brew services inventory failed; falling back to launchctl"
                );
                self.collect_launchctl_services(names)
            }
            Err(error) => {
                tracing::debug!(
                    error = %error,
                    "brew services inventory could not start; falling back to launchctl"
                );
                self.collect_launchctl_services(names)
            }
        }
    }

    fn collect_launchctl_services(&self, names: &[String]) -> HashMap<String, String> {
        let uid = self
            .runner
            .capture(&CommandRequest::new("id").args(["-u"]))
            .ok()
            .filter(|output| output.success)
            .map(|output| output.stdout.trim().to_owned())
            .filter(|uid| !uid.is_empty());
        if uid.is_none() {
            tracing::warn!("unable to determine user ID for launchctl service fallback");
        }

        names
            .iter()
            .filter_map(|name| {
                let label = format!("homebrew.mxcl.{}", package_token(name));
                let running = uid.as_ref().is_some_and(|uid| {
                    self.runner
                        .capture(
                            &CommandRequest::new("launchctl")
                                .args(["print", &format!("gui/{uid}/{label}")]),
                        )
                        .is_ok_and(|output| output.success)
                });
                if running {
                    return Some((name.clone(), "started".to_owned()));
                }

                let plist = self
                    .home
                    .join("Library/LaunchAgents")
                    .join(format!("{label}.plist"));
                plist.exists().then(|| (name.clone(), "stopped".to_owned()))
            })
            .collect()
    }

    pub(super) fn brew_request<I, S>(&self, arguments: I) -> CommandRequest
    where
        I: IntoIterator<Item = S>,
        S: Into<std::ffi::OsString>,
    {
        CommandRequest::new(
            self.brew
                .clone()
                .unwrap_or_else(|| std::path::PathBuf::from("brew")),
        )
        .args(arguments)
        .env("HOMEBREW_NO_AUTO_UPDATE", "1")
    }

    fn command_lines(&self, request: CommandRequest) -> Vec<String> {
        self.runner
            .capture(&request)
            .ok()
            .filter(|output| output.success)
            .map(|output| {
                output
                    .stdout
                    .lines()
                    .map(str::trim)
                    .filter(|line| !line.is_empty())
                    .map(str::to_owned)
                    .collect()
            })
            .unwrap_or_default()
    }
}

fn parse_service(line: &str) -> Option<(String, String)> {
    let mut fields = line.split_whitespace();
    Some((fields.next()?.to_owned(), fields.next()?.to_owned()))
}

fn is_major_version_alias(name: &str) -> bool {
    name.rsplit_once('@').is_some_and(|(_, version)| {
        !version.is_empty() && version.chars().all(|ch| ch.is_ascii_digit())
    })
}

#[derive(Deserialize)]
struct BrewInfo {
    formulae: Vec<BrewFormulaInfo>,
}

#[derive(Deserialize)]
struct BrewFormulaInfo {
    full_name: String,
    installed: Vec<serde_json::Value>,
}

#[cfg(test)]
mod tests {
    use std::{collections::BTreeMap, sync::Arc};

    use tempfile::tempdir;

    use crate::{
        config::{Config, Resource},
        engine::test_support::StubRunner,
        system::CommandOutput,
    };

    use super::*;

    fn service_config(name: &str) -> Config {
        Config {
            version: 1,
            default_profiles: Vec::new(),
            profiles: BTreeMap::new(),
            resources: vec![Resource {
                id: format!("service.{name}"),
                description: format!("{name} service"),
                tags: Vec::new(),
                depends_on: Vec::new(),
                kind: ResourceKind::BrewService {
                    name: name.to_owned(),
                },
            }],
        }
    }

    fn formula_config(name: &str) -> Config {
        Config {
            version: 1,
            default_profiles: Vec::new(),
            profiles: BTreeMap::new(),
            resources: vec![Resource {
                id: format!("formula.{name}"),
                description: format!("{name} formula"),
                tags: Vec::new(),
                depends_on: Vec::new(),
                kind: ResourceKind::BrewFormula {
                    name: name.to_owned(),
                    executable: None,
                },
            }],
        }
    }

    #[test]
    fn resolves_installed_major_version_aliases() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        let runner = Arc::new(StubRunner::with_captured([
            CommandOutput {
                success: true,
                stdout: "python@3.14\n".to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: r#"{"formulae":[{"full_name":"python@3.14","installed":[{"version":"3.14.5"}]}],"casks":[]}"#
                    .to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: String::new(),
                stderr: String::new(),
            },
        ]));
        let engine = Engine::with_runner(
            formula_config("python@3"),
            repo.path().to_owned(),
            home.path().to_owned(),
            Some(PathBuf::from("/opt/homebrew/bin/brew")),
            runner.clone(),
        );

        let inventory = engine.inventory(&["formula.python@3".to_owned()]);

        assert_eq!(
            inventory
                .formula_aliases
                .get("python@3")
                .map(String::as_str),
            Some("python@3.14")
        );
        assert_eq!(
            runner.requests()[1].arguments,
            ["info", "--json=v2", "python@3"]
        );
    }

    #[test]
    fn major_version_alias_requires_only_digits_after_at_sign() {
        assert!(is_major_version_alias("python@3"));
        assert!(is_major_version_alias("openjdk@21"));
        assert!(!is_major_version_alias("python@3.14"));
        assert!(!is_major_version_alias("ripgrep"));
    }

    #[test]
    fn launchctl_fallback_detects_services_when_brew_services_fails() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        let runner = Arc::new(StubRunner::with_captured([
            CommandOutput {
                success: true,
                stdout: "sketchybar\n".to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: String::new(),
                stderr: String::new(),
            },
            CommandOutput {
                success: false,
                stdout: String::new(),
                stderr: "brew services cannot run under tmux".to_owned(),
            },
            CommandOutput {
                success: true,
                stdout: "503\n".to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: "state = running\n".to_owned(),
                stderr: String::new(),
            },
        ]));
        let engine = Engine::with_runner(
            service_config("sketchybar"),
            repo.path().to_owned(),
            home.path().to_owned(),
            Some(PathBuf::from("/opt/homebrew/bin/brew")),
            runner.clone(),
        );

        let inventory = engine.inventory(&["service.sketchybar".to_owned()]);

        assert_eq!(
            inventory.services.get("sketchybar").map(String::as_str),
            Some("started")
        );
        let requests = runner.requests();
        assert_eq!(requests[2].arguments, ["services", "list"]);
        assert_eq!(
            requests[4].arguments,
            ["print", "gui/503/homebrew.mxcl.sketchybar"]
        );
    }

    #[test]
    fn launchctl_supplements_incomplete_brew_service_inventory() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        let runner = Arc::new(StubRunner::with_captured([
            CommandOutput {
                success: true,
                stdout: "sketchybar\n".to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: String::new(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: "Name    Status User File\nunbound none\n".to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: "503\n".to_owned(),
                stderr: String::new(),
            },
            CommandOutput {
                success: true,
                stdout: "state = running\n".to_owned(),
                stderr: String::new(),
            },
        ]));
        let engine = Engine::with_runner(
            service_config("sketchybar"),
            repo.path().to_owned(),
            home.path().to_owned(),
            Some(PathBuf::from("/opt/homebrew/bin/brew")),
            runner,
        );

        let inventory = engine.inventory(&["service.sketchybar".to_owned()]);

        assert_eq!(
            inventory.services.get("unbound").map(String::as_str),
            Some("none")
        );
        assert_eq!(
            inventory.services.get("sketchybar").map(String::as_str),
            Some("started")
        );
    }

    #[test]
    fn launch_agent_plist_detects_registered_but_stopped_services() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        let agents = home.path().join("Library/LaunchAgents");
        std::fs::create_dir_all(&agents).unwrap();
        std::fs::write(agents.join("homebrew.mxcl.borders.plist"), "plist").unwrap();
        let runner = Arc::new(StubRunner::with_captured([
            CommandOutput {
                success: true,
                ..CommandOutput::default()
            },
            CommandOutput {
                success: true,
                ..CommandOutput::default()
            },
            CommandOutput {
                success: false,
                stderr: "brew services cannot run under tmux".to_owned(),
                ..CommandOutput::default()
            },
            CommandOutput {
                success: true,
                stdout: "503\n".to_owned(),
                ..CommandOutput::default()
            },
            CommandOutput {
                success: false,
                ..CommandOutput::default()
            },
        ]));
        let engine = Engine::with_runner(
            service_config("borders"),
            repo.path().to_owned(),
            home.path().to_owned(),
            Some(PathBuf::from("/opt/homebrew/bin/brew")),
            runner,
        );

        let inventory = engine.inventory(&["service.borders".to_owned()]);

        assert_eq!(
            inventory.services.get("borders").map(String::as_str),
            Some("stopped")
        );
    }
}
