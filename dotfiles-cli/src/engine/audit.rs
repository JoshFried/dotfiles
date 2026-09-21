//! Resource-specific desired-state inspection.

use std::{fs, path::Path};

use crate::{
    config::{Resource, ResourceKind},
    domain::{AuditResult, Status},
    system::CommandRequest,
};

use super::{
    Engine,
    inventory::Inventory,
    util::{normalize_git_url, package_token, paths_equivalent},
};

impl Engine {
    pub(super) fn audit(&self, resource: &Resource, inventory: &Inventory) -> AuditResult {
        let mut result = match &resource.kind {
            ResourceKind::BrewFormula {
                name,
                executable,
                fallback_paths,
            } => self.audit_formula(
                resource,
                name,
                executable.as_deref(),
                fallback_paths,
                inventory,
            ),
            ResourceKind::BrewCask { name, app } => {
                self.audit_cask(resource, name, app.as_deref(), inventory)
            }
            ResourceKind::BrewService { name } => self.audit_service(resource, name, inventory),
            ResourceKind::Symlink {
                source,
                destination,
            } => self.audit_symlink(resource, source, destination),
            ResourceKind::GitRepo { url, destination } => {
                self.audit_git_repo(resource, url, destination)
            }
        };
        if result.fixable && !result.status.is_healthy() {
            result.action = Some(self.action(resource));
        }
        result
    }

    fn audit_formula(
        &self,
        resource: &Resource,
        name: &str,
        executable: Option<&str>,
        fallback_paths: &[String],
        inventory: &Inventory,
    ) -> AuditResult {
        if !inventory.brew_available {
            return result(
                resource,
                Status::Blocked,
                "Homebrew is unavailable",
                format!("Homebrew formula {name}"),
                "brew not found",
                false,
            );
        }
        if inventory.formulae.contains(package_token(name)) {
            return result(
                resource,
                Status::Healthy,
                "Installed through Homebrew",
                format!("Homebrew formula {name}"),
                "installed",
                false,
            );
        }
        if let Some(canonical) = inventory.formula_aliases.get(package_token(name)) {
            return result(
                resource,
                Status::Healthy,
                format!("Installed through Homebrew as {canonical}"),
                format!("Homebrew formula {name} (floating major version)"),
                canonical,
                false,
            );
        }
        let executable = executable
            .map(str::to_owned)
            .or_else(|| super::inventory::formula_executable(name, None));
        if let Some(path) = executable
            .as_deref()
            .and_then(|command| inventory.executables.get(command))
        {
            return result(
                resource,
                Status::Misplaced,
                "Executable exists but is not managed by Homebrew",
                format!("Homebrew formula {name}"),
                path.display().to_string(),
                false,
            );
        }
        if let Some(path) = fallback_paths
            .iter()
            .map(|path| self.expand_home(path))
            .find(|path| path.exists())
        {
            return result(
                resource,
                Status::Drifted,
                "Artifact exists but is not managed by Homebrew",
                format!("Homebrew formula {name}"),
                path.display().to_string(),
                false,
            );
        }
        result(
            resource,
            Status::Missing,
            "Formula is not installed",
            format!("Homebrew formula {name}"),
            "not installed",
            true,
        )
    }

    fn audit_cask(
        &self,
        resource: &Resource,
        name: &str,
        app: Option<&str>,
        inventory: &Inventory,
    ) -> AuditResult {
        if !inventory.brew_available {
            return result(
                resource,
                Status::Blocked,
                "Homebrew is unavailable",
                format!("Homebrew cask {name}"),
                "brew not found",
                false,
            );
        }
        if inventory.casks.contains(package_token(name)) {
            return result(
                resource,
                Status::Healthy,
                "Installed through Homebrew",
                format!("Homebrew cask {name}"),
                "installed",
                false,
            );
        }
        if let Some(app) = app {
            let system_app = Path::new("/Applications").join(app);
            let user_app = self.home.join("Applications").join(app);
            if user_app.exists() {
                return result(
                    resource,
                    Status::Misplaced,
                    "Application is installed in the user Applications directory",
                    system_app.display().to_string(),
                    user_app.display().to_string(),
                    false,
                );
            }
            if system_app.exists() {
                return result(
                    resource,
                    Status::Drifted,
                    "Application exists but is not managed by Homebrew",
                    format!("Homebrew cask {name}"),
                    system_app.display().to_string(),
                    false,
                );
            }
        }
        result(
            resource,
            Status::Missing,
            "Cask is not installed",
            format!("Homebrew cask {name}"),
            "not installed",
            true,
        )
    }

    fn audit_service(&self, resource: &Resource, name: &str, inventory: &Inventory) -> AuditResult {
        if !inventory.brew_available {
            return result(
                resource,
                Status::Blocked,
                "Homebrew is unavailable",
                format!("running service {name}"),
                "brew not found",
                false,
            );
        }
        match inventory.services.get(name).map(String::as_str) {
            Some("started") => result(
                resource,
                Status::Healthy,
                "Service is running",
                format!("running service {name}"),
                "started",
                false,
            ),
            Some(status) => result(
                resource,
                Status::Drifted,
                "Service is installed but not running",
                format!("running service {name}"),
                status,
                true,
            ),
            None => result(
                resource,
                Status::Missing,
                "Service is not registered",
                format!("running service {name}"),
                "not registered",
                true,
            ),
        }
    }

    fn audit_symlink(&self, resource: &Resource, source: &str, destination: &str) -> AuditResult {
        let source = self.repo.join(source);
        let destination = self.expand_home(destination);
        if !source.exists() {
            return result(
                resource,
                Status::Blocked,
                "Repository source does not exist",
                source.display().to_string(),
                "missing source",
                false,
            );
        }
        match fs::symlink_metadata(&destination) {
            Ok(metadata) if metadata.file_type().is_symlink() => {
                let target = match fs::read_link(&destination) {
                    Ok(target) if target.is_absolute() => target,
                    Ok(target) => destination.parent().unwrap_or(Path::new("/")).join(target),
                    Err(error) => {
                        return result(
                            resource,
                            Status::Drifted,
                            format!("Unable to read symlink: {error}"),
                            source.display().to_string(),
                            destination.display().to_string(),
                            true,
                        );
                    }
                };
                if paths_equivalent(&target, &source) {
                    result(
                        resource,
                        Status::Healthy,
                        "Symlink points to the repository",
                        source.display().to_string(),
                        target.display().to_string(),
                        false,
                    )
                } else {
                    result(
                        resource,
                        Status::Misplaced,
                        "Symlink points to a different source",
                        source.display().to_string(),
                        target.display().to_string(),
                        true,
                    )
                }
            }
            Ok(_) => result(
                resource,
                Status::Drifted,
                "Destination exists but is not a symlink",
                source.display().to_string(),
                destination.display().to_string(),
                true,
            ),
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => result(
                resource,
                Status::Missing,
                "Symlink is missing",
                source.display().to_string(),
                "missing",
                true,
            ),
            Err(error) => result(
                resource,
                Status::Blocked,
                format!("Unable to inspect destination: {error}"),
                source.display().to_string(),
                destination.display().to_string(),
                false,
            ),
        }
    }

    fn audit_git_repo(&self, resource: &Resource, url: &str, destination: &str) -> AuditResult {
        let destination = self.expand_home(destination);
        if !destination.join(".git").is_dir() {
            let status = if destination.exists() {
                Status::Drifted
            } else {
                Status::Missing
            };
            return result(
                resource,
                status,
                "Git repository is missing or invalid",
                url,
                destination.display().to_string(),
                !destination.exists(),
            );
        }
        let output = self.runner.capture(&CommandRequest::new("git").args([
            "-C",
            destination.to_string_lossy().as_ref(),
            "config",
            "--get",
            "remote.origin.url",
        ]));
        let actual = output
            .ok()
            .filter(|output| output.success)
            .map(|output| output.stdout.trim().to_owned())
            .unwrap_or_default();
        if normalize_git_url(&actual) == normalize_git_url(url) {
            result(
                resource,
                Status::Healthy,
                "Repository has the expected origin",
                url,
                actual,
                false,
            )
        } else {
            result(
                resource,
                Status::Drifted,
                "Repository has an unexpected origin",
                url,
                actual,
                false,
            )
        }
    }
}

fn result(
    resource: &Resource,
    status: Status,
    summary: impl Into<String>,
    desired: impl Into<String>,
    actual: impl Into<String>,
    fixable: bool,
) -> AuditResult {
    AuditResult {
        id: resource.id.clone(),
        description: resource.description.clone(),
        status,
        summary: summary.into(),
        desired: desired.into(),
        actual: actual.into(),
        fixable,
        action: None,
    }
}

#[cfg(test)]
mod tests {
    use std::{
        collections::{HashMap, HashSet},
        fs,
        os::unix::fs as unix_fs,
        path::PathBuf,
        sync::Arc,
    };

    use tempfile::tempdir;

    use crate::{
        config::{Config, Resource, ResourceKind},
        system::SystemCommandRunner,
    };

    use super::*;

    fn engine(repo: &Path, home: &Path) -> Engine {
        Engine::with_runner(
            Config {
                version: 1,
                default_profiles: Vec::new(),
                profiles: Default::default(),
                resources: Vec::new(),
            },
            repo.to_owned(),
            home.to_owned(),
            None,
            Arc::new(SystemCommandRunner),
        )
    }

    fn inventory(formulae: &[&str], services: &[(&str, &str)]) -> Inventory {
        Inventory {
            brew_available: true,
            formulae: formulae.iter().map(ToString::to_string).collect(),
            formula_aliases: HashMap::new(),
            casks: HashSet::new(),
            services: services
                .iter()
                .map(|(name, status)| (name.to_string(), status.to_string()))
                .collect::<HashMap<_, _>>(),
            executables: HashMap::new(),
        }
    }

    fn formula() -> Resource {
        Resource {
            id: "formula.ripgrep".to_owned(),
            description: "Ripgrep".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::BrewFormula {
                name: "ripgrep".to_owned(),
                executable: None,
                fallback_paths: Vec::new(),
            },
        }
    }

    #[test]
    fn installed_formulae_are_healthy() {
        let directory = tempdir().unwrap();
        let result = engine(directory.path(), directory.path())
            .audit(&formula(), &inventory(&["ripgrep"], &[]));
        assert_eq!(result.status, Status::Healthy);
        assert!(!result.fixable);
    }

    #[test]
    fn installed_formula_aliases_are_healthy() {
        let directory = tempdir().unwrap();
        let mut inventory = inventory(&["python@3.14"], &[]);
        inventory
            .formula_aliases
            .insert("python@3".to_owned(), "python@3.14".to_owned());
        let resource = Resource {
            id: "formula.python".to_owned(),
            description: "Python".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::BrewFormula {
                name: "python@3".to_owned(),
                executable: None,
                fallback_paths: Vec::new(),
            },
        };

        let result = engine(directory.path(), directory.path()).audit(&resource, &inventory);

        assert_eq!(result.status, Status::Healthy);
        assert_eq!(result.actual, "python@3.14");
        assert_eq!(result.summary, "Installed through Homebrew as python@3.14");
    }

    #[test]
    fn missing_formulae_have_an_apply_action() {
        let directory = tempdir().unwrap();
        let result =
            engine(directory.path(), directory.path()).audit(&formula(), &inventory(&[], &[]));
        assert_eq!(result.status, Status::Missing);
        assert_eq!(result.action.as_deref(), Some("brew install ripgrep"));
    }

    #[test]
    fn formulae_are_blocked_without_homebrew() {
        let directory = tempdir().unwrap();
        let mut unavailable = inventory(&[], &[]);
        unavailable.brew_available = false;
        let result = engine(directory.path(), directory.path()).audit(&formula(), &unavailable);
        assert_eq!(result.status, Status::Blocked);
        assert!(!result.fixable);
    }

    #[test]
    fn formula_executables_from_other_installers_are_misplaced() {
        let directory = tempdir().unwrap();
        let mut inventory = inventory(&[], &[]);
        inventory
            .executables
            .insert("eza".to_owned(), PathBuf::from("/home/test/.cargo/bin/eza"));
        let resource = Resource {
            id: "formula.eza".to_owned(),
            description: "Eza".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::BrewFormula {
                name: "eza".to_owned(),
                executable: Some("eza".to_owned()),
                fallback_paths: Vec::new(),
            },
        };

        let result = engine(directory.path(), directory.path()).audit(&resource, &inventory);

        assert_eq!(result.status, Status::Misplaced);
        assert_eq!(result.actual, "/home/test/.cargo/bin/eza");
        assert!(!result.fixable);
        assert!(result.action.is_none());
    }

    #[test]
    fn formula_artifacts_outside_homebrew_are_drifted() {
        let directory = tempdir().unwrap();
        let font = directory.path().join("Library/Fonts/app-font.ttf");
        fs::create_dir_all(font.parent().unwrap()).unwrap();
        fs::write(&font, "font").unwrap();
        let resource = Resource {
            id: "formula.app-font".to_owned(),
            description: "App font".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::BrewFormula {
                name: "owner/tap/app-font".to_owned(),
                executable: None,
                fallback_paths: vec!["~/Library/Fonts/app-font.ttf".to_owned()],
            },
        };

        let result =
            engine(directory.path(), directory.path()).audit(&resource, &inventory(&[], &[]));

        assert_eq!(result.status, Status::Drifted);
        assert_eq!(result.actual, font.display().to_string());
        assert!(!result.fixable);
    }

    #[test]
    fn stopped_services_are_drifted_and_fixable() {
        let directory = tempdir().unwrap();
        let resource = Resource {
            id: "service.test".to_owned(),
            description: "Test service".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::BrewService {
                name: "test".to_owned(),
            },
        };
        let result = engine(directory.path(), directory.path())
            .audit(&resource, &inventory(&[], &[("test", "stopped")]));
        assert_eq!(result.status, Status::Drifted);
        assert!(result.fixable);
    }

    #[test]
    fn correct_symlinks_are_healthy() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        fs::write(repo.path().join("source"), "value").unwrap();
        unix_fs::symlink(repo.path().join("source"), home.path().join("destination")).unwrap();
        let resource = Resource {
            id: "symlink.test".to_owned(),
            description: "Test link".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::Symlink {
                source: "source".to_owned(),
                destination: "~/destination".to_owned(),
            },
        };
        let result = engine(repo.path(), home.path()).audit(&resource, &inventory(&[], &[]));
        assert_eq!(result.status, Status::Healthy);
    }

    #[test]
    fn regular_files_at_symlink_destinations_are_drifted() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        fs::write(repo.path().join("source"), "desired").unwrap();
        fs::write(home.path().join("destination"), "actual").unwrap();
        let resource = Resource {
            id: "symlink.test".to_owned(),
            description: "Test link".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::Symlink {
                source: "source".to_owned(),
                destination: "~/destination".to_owned(),
            },
        };
        let result = engine(repo.path(), home.path()).audit(&resource, &inventory(&[], &[]));
        assert_eq!(result.status, Status::Drifted);
        assert!(result.fixable);
    }
}
