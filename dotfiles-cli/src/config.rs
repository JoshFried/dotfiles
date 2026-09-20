//! Declarative manifest types, loading, and structural validation.

use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::Path,
};

use anyhow::{Context, Result, bail};
use serde::Deserialize;

/// Validated dotfiles manifest.
#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    /// Manifest schema version.
    pub version: u32,
    /// Profiles selected when no explicit filter is provided.
    #[serde(default)]
    pub default_profiles: Vec<String>,
    /// Named groups of resource identifiers.
    #[serde(default)]
    pub profiles: BTreeMap<String, Vec<String>>,
    /// Resources describing the desired machine state.
    pub resources: Vec<Resource>,
}

/// A named, selectable unit of desired state.
#[derive(Clone, Debug, Deserialize)]
pub struct Resource {
    /// Stable resource identifier.
    pub id: String,
    /// Human-readable purpose.
    pub description: String,
    /// Searchable categories used by selection filters.
    #[serde(default)]
    pub tags: Vec<String>,
    /// Resource identifiers that must be handled first.
    #[serde(default)]
    pub depends_on: Vec<String>,
    /// Type-specific desired state.
    #[serde(flatten)]
    pub kind: ResourceKind,
}

/// Supported resource implementations.
#[derive(Clone, Debug, Deserialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum ResourceKind {
    /// A Homebrew formula, optionally recognizing an alternate executable.
    BrewFormula {
        /// Formula or fully qualified tap name.
        name: String,
        /// Executable used to detect another installation source.
        executable: Option<String>,
    },
    /// A Homebrew cask with an optional application bundle fallback.
    BrewCask {
        /// Cask or fully qualified tap name.
        name: String,
        /// Application bundle used to detect unmanaged installations.
        app: Option<String>,
    },
    /// A Homebrew-managed background service.
    BrewService {
        /// Formula service name.
        name: String,
    },
    /// A repository path linked into the home directory.
    Symlink {
        /// Source path relative to the repository.
        source: String,
        /// Destination path, with `~` resolved against the user home.
        destination: String,
    },
    /// A Git checkout with an expected origin.
    GitRepo {
        /// Expected remote origin URL.
        url: String,
        /// Checkout destination.
        destination: String,
    },
}

impl Config {
    /// Loads and validates a manifest from disk.
    ///
    /// # Errors
    ///
    /// Returns an error for unreadable or invalid TOML, unsupported versions,
    /// duplicate identifiers, missing references, or dependency cycles.
    pub fn load(path: &Path) -> Result<Self> {
        tracing::debug!(path = %path.display(), "loading configuration");
        let contents = fs::read_to_string(path)
            .with_context(|| format!("failed to read configuration {}", path.display()))?;
        tracing::trace!(bytes = contents.len(), "configuration file read");
        let config: Self = toml::from_str(&contents)
            .with_context(|| format!("failed to parse configuration {}", path.display()))?;
        config.validate()?;
        tracing::info!(
            path = %path.display(),
            resource_count = config.resources.len(),
            profile_count = config.profiles.len(),
            "configuration loaded"
        );
        Ok(config)
    }

    /// Finds a resource by its stable identifier.
    pub fn resource(&self, id: &str) -> Option<&Resource> {
        self.resources.iter().find(|resource| resource.id == id)
    }

    fn validate(&self) -> Result<()> {
        tracing::debug!(
            version = self.version,
            resource_count = self.resources.len(),
            profile_count = self.profiles.len(),
            "validating configuration"
        );
        if self.version != 1 {
            bail!("unsupported configuration version {}", self.version);
        }

        let mut ids = BTreeSet::new();
        for resource in &self.resources {
            if !ids.insert(resource.id.as_str()) {
                bail!("duplicate resource id '{}'", resource.id);
            }
        }

        for (profile, resources) in &self.profiles {
            for id in resources {
                if !ids.contains(id.as_str()) {
                    bail!("profile '{profile}' references unknown resource '{id}'");
                }
            }
        }

        for profile in &self.default_profiles {
            if !self.profiles.contains_key(profile) {
                bail!("unknown default profile '{profile}'");
            }
        }

        for resource in &self.resources {
            for dependency in &resource.depends_on {
                if !ids.contains(dependency.as_str()) {
                    bail!(
                        "resource '{}' depends on unknown resource '{}'",
                        resource.id,
                        dependency
                    );
                }
            }
        }

        self.validate_dependency_graph()?;
        Ok(())
    }

    fn validate_dependency_graph(&self) -> Result<()> {
        fn visit<'a>(
            config: &'a Config,
            id: &'a str,
            visiting: &mut BTreeSet<&'a str>,
            visited: &mut BTreeSet<&'a str>,
        ) -> Result<()> {
            if visited.contains(id) {
                return Ok(());
            }
            if !visiting.insert(id) {
                bail!("dependency cycle involving '{id}'");
            }
            let resource = config
                .resource(id)
                .with_context(|| format!("unknown resource '{id}'"))?;
            for dependency in &resource.depends_on {
                visit(config, dependency, visiting, visited)?;
            }
            visiting.remove(id);
            visited.insert(id);
            Ok(())
        }

        let mut visiting = BTreeSet::new();
        let mut visited = BTreeSet::new();
        for resource in &self.resources {
            visit(self, &resource.id, &mut visiting, &mut visited)?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use std::io::Write;

    use tempfile::NamedTempFile;

    use super::*;

    fn load(contents: &str) -> Result<Config> {
        let mut file = NamedTempFile::new()?;
        file.write_all(contents.as_bytes())?;
        Config::load(file.path())
    }

    #[test]
    fn loads_a_valid_configuration() {
        let config = load(
            r#"
            version = 1
            default_profiles = ["core"]
            [profiles]
            core = ["formula.git"]
            [[resources]]
            id = "formula.git"
            description = "Git"
            kind = "brew_formula"
            name = "git"
            "#,
        )
        .unwrap();
        assert_eq!(config.resources.len(), 1);
    }

    #[test]
    fn rejects_unsupported_versions() {
        let error = load("version = 2\nresources = []").unwrap_err();
        assert!(
            error
                .to_string()
                .contains("unsupported configuration version")
        );
    }

    #[test]
    fn rejects_duplicate_resource_ids() {
        let error = load(
            r#"
            version = 1
            [[resources]]
            id = "same"
            description = "One"
            kind = "brew_formula"
            name = "one"
            [[resources]]
            id = "same"
            description = "Two"
            kind = "brew_formula"
            name = "two"
            "#,
        )
        .unwrap_err();
        assert!(error.to_string().contains("duplicate resource id"));
    }

    #[test]
    fn rejects_unknown_profile_resources() {
        let error = load(
            r#"
            version = 1
            resources = []
            [profiles]
            core = ["missing"]
            "#,
        )
        .unwrap_err();
        assert!(error.to_string().contains("unknown resource"));
    }

    #[test]
    fn rejects_unknown_dependencies() {
        let error = load(
            r#"
            version = 1
            [[resources]]
            id = "tool"
            description = "Tool"
            depends_on = ["missing"]
            kind = "brew_formula"
            name = "tool"
            "#,
        )
        .unwrap_err();
        assert!(error.to_string().contains("depends on unknown resource"));
    }

    #[test]
    fn rejects_dependency_cycles_during_loading() {
        let error = load(
            r#"
            version = 1
            [[resources]]
            id = "one"
            description = "One"
            depends_on = ["two"]
            kind = "brew_formula"
            name = "one"
            [[resources]]
            id = "two"
            description = "Two"
            depends_on = ["one"]
            kind = "brew_formula"
            name = "two"
            "#,
        )
        .unwrap_err();
        assert!(error.to_string().contains("dependency cycle"));
    }

    #[test]
    fn rejects_unknown_top_level_fields() {
        let error = load(
            r#"
            version = 1
            unexpected = true
            resources = []
            "#,
        )
        .unwrap_err();
        assert!(format!("{error:#}").contains("unknown field"));
    }
}
