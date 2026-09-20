//! Filter resolution and dependency ordering.

use std::collections::{BTreeSet, HashSet};

use anyhow::{Context, Result, bail};

use crate::{cli::FilterArgs, domain::ResourceExplanation};

use super::Engine;

impl Engine {
    /// Resolves filters into a dependency-ordered list of resource identifiers.
    ///
    /// With no explicit filters, the manifest's default profiles are selected.
    ///
    /// # Errors
    ///
    /// Returns an error for unknown profiles, tags, resources, or dependency
    /// cycles.
    pub fn select(&self, filter: &FilterArgs) -> Result<Vec<String>> {
        tracing::debug!(
            profiles = ?filter.profile,
            tags = ?filter.tag,
            resources = ?filter.resources,
            "selecting resources"
        );
        let mut selected = BTreeSet::new();
        let has_filter =
            !filter.profile.is_empty() || !filter.tag.is_empty() || !filter.resources.is_empty();
        let profiles = if has_filter {
            &filter.profile
        } else {
            &self.config.default_profiles
        };

        for profile in profiles {
            selected.extend(
                self.config
                    .profiles
                    .get(profile)
                    .with_context(|| format!("unknown profile '{profile}'"))?
                    .iter()
                    .cloned(),
            );
        }
        for tag in &filter.tag {
            let matches: Vec<_> = self
                .config
                .resources
                .iter()
                .filter(|resource| resource.tags.contains(tag))
                .map(|resource| resource.id.clone())
                .collect();
            if matches.is_empty() {
                bail!("unknown or unused tag '{tag}'");
            }
            selected.extend(matches);
        }
        for id in &filter.resources {
            if self.config.resource(id).is_none() {
                bail!("unknown resource '{id}'");
            }
            selected.insert(id.clone());
        }

        let selected = self.expand_dependencies(selected)?;
        tracing::info!(resource_count = selected.len(), resources = ?selected, "resources selected");
        Ok(selected)
    }

    /// Describes a resource and its direct dependency relationships.
    ///
    /// # Errors
    ///
    /// Returns an error when the identifier is unknown.
    pub fn explain(&self, id: &str) -> Result<ResourceExplanation> {
        let resource = self
            .config
            .resource(id)
            .with_context(|| format!("unknown resource '{id}'"))?;
        let dependents: Vec<_> = self
            .config
            .resources
            .iter()
            .filter(|candidate| {
                candidate
                    .depends_on
                    .iter()
                    .any(|dependency| dependency == id)
            })
            .map(|candidate| candidate.id.clone())
            .collect();
        Ok(ResourceExplanation {
            id: resource.id.clone(),
            description: resource.description.clone(),
            tags: resource.tags.clone(),
            dependencies: resource.depends_on.clone(),
            dependents,
        })
    }

    fn expand_dependencies(&self, selected: BTreeSet<String>) -> Result<Vec<String>> {
        let mut ordered = Vec::new();
        let mut visiting = HashSet::new();
        let mut visited = HashSet::new();
        for id in selected {
            self.visit(&id, &mut visiting, &mut visited, &mut ordered)?;
        }
        Ok(ordered)
    }

    fn visit(
        &self,
        id: &str,
        visiting: &mut HashSet<String>,
        visited: &mut HashSet<String>,
        ordered: &mut Vec<String>,
    ) -> Result<()> {
        if visited.contains(id) {
            return Ok(());
        }
        if !visiting.insert(id.to_owned()) {
            bail!("dependency cycle involving '{id}'");
        }
        let resource = self
            .config
            .resource(id)
            .with_context(|| format!("unknown resource '{id}'"))?;
        for dependency in &resource.depends_on {
            self.visit(dependency, visiting, visited, ordered)?;
        }
        visiting.remove(id);
        visited.insert(id.to_owned());
        ordered.push(id.to_owned());
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use std::{collections::BTreeMap, path::PathBuf, sync::Arc};

    use crate::{
        config::{Config, Resource, ResourceKind},
        system::SystemCommandRunner,
    };

    use super::*;

    fn engine(resources: Vec<Resource>, profiles: BTreeMap<String, Vec<String>>) -> Engine {
        Engine::with_runner(
            Config {
                version: 1,
                default_profiles: vec!["default".to_owned()],
                profiles,
                resources,
            },
            PathBuf::from("/repo"),
            PathBuf::from("/home/test"),
            None,
            Arc::new(SystemCommandRunner),
        )
    }

    fn formula(id: &str, dependencies: &[&str]) -> Resource {
        Resource {
            id: id.to_owned(),
            description: id.to_owned(),
            tags: vec!["tools".to_owned()],
            depends_on: dependencies.iter().map(ToString::to_string).collect(),
            kind: ResourceKind::BrewFormula {
                name: id.to_owned(),
                executable: None,
            },
        }
    }

    #[test]
    fn dependencies_are_ordered_before_dependents() {
        let engine = engine(
            vec![formula("child", &["parent"]), formula("parent", &[])],
            BTreeMap::from([("default".to_owned(), vec!["child".to_owned()])]),
        );
        assert_eq!(
            engine.select(&FilterArgs::default()).unwrap(),
            ["parent", "child"]
        );
    }

    #[test]
    fn explicit_selection_does_not_include_default_profiles() {
        let engine = engine(
            vec![formula("default", &[]), formula("selected", &[])],
            BTreeMap::from([("default".to_owned(), vec!["default".to_owned()])]),
        );
        let filter = FilterArgs {
            resources: vec!["selected".to_owned()],
            ..FilterArgs::default()
        };
        assert_eq!(engine.select(&filter).unwrap(), ["selected"]);
    }

    #[test]
    fn tags_select_all_matching_resources() {
        let engine = engine(
            vec![formula("one", &[]), formula("two", &[])],
            BTreeMap::from([("default".to_owned(), Vec::new())]),
        );
        let filter = FilterArgs {
            tag: vec!["tools".to_owned()],
            ..FilterArgs::default()
        };
        assert_eq!(engine.select(&filter).unwrap(), ["one", "two"]);
    }

    #[test]
    fn cycles_are_rejected() {
        let engine = engine(
            vec![formula("one", &["two"]), formula("two", &["one"])],
            BTreeMap::from([("default".to_owned(), vec!["one".to_owned()])]),
        );
        assert!(
            engine
                .select(&FilterArgs::default())
                .unwrap_err()
                .to_string()
                .contains("cycle")
        );
    }

    #[test]
    fn unknown_filters_are_rejected() {
        let engine = engine(
            vec![formula("one", &[])],
            BTreeMap::from([("default".to_owned(), vec!["one".to_owned()])]),
        );
        let filter = FilterArgs {
            resources: vec!["missing".to_owned()],
            ..FilterArgs::default()
        };
        assert!(engine.select(&filter).is_err());
    }

    #[test]
    fn explanation_contains_relationships() {
        let engine = engine(
            vec![formula("parent", &[]), formula("child", &["parent"])],
            BTreeMap::from([("default".to_owned(), vec!["child".to_owned()])]),
        );

        let explanation = engine.explain("parent").unwrap();

        assert_eq!(explanation.id, "parent");
        assert_eq!(explanation.tags, ["tools"]);
        assert!(explanation.dependencies.is_empty());
        assert_eq!(explanation.dependents, ["child"]);
    }
}
