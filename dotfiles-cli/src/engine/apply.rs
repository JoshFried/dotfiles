//! Resource action descriptions and safe reconciliation implementations.

use std::{
    ffi::OsString,
    fs,
    os::unix::fs as unix_fs,
    path::{Path, PathBuf},
    time::{SystemTime, UNIX_EPOCH},
};

use anyhow::{Context, Result, bail};

use crate::{
    config::{Resource, ResourceKind},
    system::CommandRequest,
};

use super::Engine;

impl Engine {
    pub(super) fn action(&self, resource: &Resource) -> String {
        match &resource.kind {
            ResourceKind::BrewFormula { name, .. } => format!("brew install {name}"),
            ResourceKind::BrewCask { name, .. } => format!("brew install --cask {name}"),
            ResourceKind::BrewService { name } => format!("brew services start {name}"),
            ResourceKind::Symlink {
                source,
                destination,
            } => {
                format!("link {destination} → {}", self.repo.join(source).display())
            }
            ResourceKind::GitRepo { url, destination } => format!("git clone {url} {destination}"),
        }
    }

    pub(super) fn apply(&self, resource: &Resource) -> Result<()> {
        match &resource.kind {
            ResourceKind::BrewFormula { name, .. } => {
                self.run_checked(self.brew_request(["install", name]))
            }
            ResourceKind::BrewCask { name, .. } => {
                self.run_checked(self.brew_request(["install", "--cask", name]))
            }
            ResourceKind::BrewService { name } => {
                self.run_checked(self.brew_request(["services", "start", name]))
            }
            ResourceKind::Symlink {
                source,
                destination,
            } => self.apply_symlink(source, destination),
            ResourceKind::GitRepo { url, destination } => self.clone_repo(url, destination),
        }
    }

    fn clone_repo(&self, url: &str, destination: &str) -> Result<()> {
        let destination = self.expand_home(destination);
        if destination.exists() {
            bail!("destination already exists: {}", destination.display());
        }
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent)?;
        }
        self.run_checked(CommandRequest::new("git").args([
            OsString::from("clone"),
            OsString::from("--depth=1"),
            OsString::from(url),
            destination.into_os_string(),
        ]))
    }

    fn apply_symlink(&self, source: &str, destination: &str) -> Result<()> {
        let source = self.repo.join(source);
        let destination = self.expand_home(destination);
        if !source.exists() {
            bail!("source does not exist: {}", source.display());
        }
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent)?;
        }
        let backup = if fs::symlink_metadata(&destination).is_ok() {
            let backup = self.backup_path(&destination)?;
            if let Some(parent) = backup.parent() {
                fs::create_dir_all(parent)?;
            }
            fs::rename(&destination, &backup)?;
            tracing::info!(
                destination = %destination.display(),
                backup = %backup.display(),
                "existing destination backed up"
            );
            Some(backup)
        } else {
            None
        };
        if let Err(error) = unix_fs::symlink(&source, &destination) {
            tracing::error!(
                source = %source.display(),
                destination = %destination.display(),
                error = %error,
                "symlink creation failed"
            );
            if let Some(backup) = backup {
                fs::rename(&backup, &destination).with_context(|| {
                    format!(
                        "failed to create symlink ({error}) and restore {}",
                        destination.display()
                    )
                })?;
            }
            return Err(error).with_context(|| format!("failed to link {}", destination.display()));
        }
        tracing::info!(
            source = %source.display(),
            destination = %destination.display(),
            "symlink created"
        );
        Ok(())
    }

    fn backup_path(&self, destination: &Path) -> Result<PathBuf> {
        let timestamp = SystemTime::now().duration_since(UNIX_EPOCH)?.as_millis();
        let relative = destination
            .strip_prefix(&self.home)
            .unwrap_or_else(|_| destination.strip_prefix("/").unwrap_or(destination));
        Ok(self
            .home
            .join(".local/state/dotfiles/backups")
            .join(timestamp.to_string())
            .join(relative))
    }

    pub(super) fn expand_home(&self, value: &str) -> PathBuf {
        value.strip_prefix("~/").map_or_else(
            || {
                if value == "~" {
                    self.home.clone()
                } else {
                    PathBuf::from(value)
                }
            },
            |relative| self.home.join(relative),
        )
    }

    fn run_checked(&self, request: CommandRequest) -> Result<()> {
        let display = request.program.display().to_string();
        match self.runner.run(&request) {
            Ok(true) => Ok(()),
            Ok(false) => bail!("{display} exited unsuccessfully"),
            Err(error) => Err(error).with_context(|| format!("failed to run {display}")),
        }
    }
}

#[cfg(test)]
mod tests {
    use std::{fs, sync::Arc};

    use tempfile::tempdir;

    use crate::{
        config::{Config, Resource, ResourceKind},
        engine::test_support::StubRunner,
    };

    use super::*;

    fn config(resource: Resource) -> Config {
        Config {
            version: 1,
            default_profiles: Vec::new(),
            profiles: Default::default(),
            resources: vec![resource],
        }
    }

    #[test]
    fn creates_missing_symlinks() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        fs::write(repo.path().join("source"), "value").unwrap();
        let resource = Resource {
            id: "symlink.test".to_owned(),
            description: "Test".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::Symlink {
                source: "source".to_owned(),
                destination: "~/destination".to_owned(),
            },
        };
        let engine = Engine::with_runner(
            config(resource.clone()),
            repo.path().to_owned(),
            home.path().to_owned(),
            None,
            Arc::new(StubRunner::default()),
        );

        engine.apply(&resource).unwrap();

        assert_eq!(
            fs::read_link(home.path().join("destination")).unwrap(),
            repo.path().join("source")
        );
    }

    #[test]
    fn existing_destinations_are_backed_up_before_linking() {
        let repo = tempdir().unwrap();
        let home = tempdir().unwrap();
        fs::write(repo.path().join("source"), "desired").unwrap();
        fs::write(home.path().join("destination"), "original").unwrap();
        let resource = Resource {
            id: "symlink.test".to_owned(),
            description: "Test".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::Symlink {
                source: "source".to_owned(),
                destination: "~/destination".to_owned(),
            },
        };
        let engine = Engine::with_runner(
            config(resource.clone()),
            repo.path().to_owned(),
            home.path().to_owned(),
            None,
            Arc::new(StubRunner::default()),
        );

        engine.apply(&resource).unwrap();

        let backup_root = home.path().join(".local/state/dotfiles/backups");
        let backup = fs::read_dir(backup_root)
            .unwrap()
            .next()
            .unwrap()
            .unwrap()
            .path()
            .join("destination");
        assert_eq!(fs::read_to_string(backup).unwrap(), "original");
    }

    #[test]
    fn brew_apply_uses_non_updating_environment() {
        let runner = Arc::new(StubRunner::with_run_results([true]));
        let resource = Resource {
            id: "formula.test".to_owned(),
            description: "Test".to_owned(),
            tags: Vec::new(),
            depends_on: Vec::new(),
            kind: ResourceKind::BrewFormula {
                name: "test".to_owned(),
                executable: None,
                fallback_paths: Vec::new(),
            },
        };
        let engine = Engine::with_runner(
            config(resource.clone()),
            PathBuf::from("/repo"),
            PathBuf::from("/home/test"),
            Some(PathBuf::from("/brew")),
            runner.clone(),
        );

        engine.apply(&resource).unwrap();

        let requests = runner.requests();
        assert_eq!(requests.len(), 1);
        assert_eq!(
            requests[0]
                .environment
                .get(std::ffi::OsStr::new("HOMEBREW_NO_AUTO_UPDATE")),
            Some(&OsString::from("1"))
        );
    }
}
