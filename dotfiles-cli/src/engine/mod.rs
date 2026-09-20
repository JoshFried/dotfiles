mod apply;
mod audit;
mod inventory;
mod selection;
#[cfg(test)]
mod test_support;
mod util;

use std::{env, path::PathBuf, sync::Arc};

use anyhow::{Context, Result};

use crate::{
    config::{Config, ResourceKind},
    domain::{AuditResult, PlannedChange},
    system::{CommandRunner, SystemCommandRunner, find_program},
};

pub struct Engine {
    pub config: Config,
    repo: PathBuf,
    home: PathBuf,
    brew: Option<PathBuf>,
    runner: Arc<dyn CommandRunner>,
}

impl Engine {
    pub fn new(config: Config, repo: PathBuf) -> Result<Self> {
        let home = env::var_os("HOME")
            .map(PathBuf::from)
            .context("HOME is not set")?;
        let brew = find_program("brew", env::var_os("PATH").as_deref());
        Ok(Self::with_runner(
            config,
            repo,
            home,
            brew,
            Arc::new(SystemCommandRunner),
        ))
    }

    pub fn with_runner(
        config: Config,
        repo: PathBuf,
        home: PathBuf,
        brew: Option<PathBuf>,
        runner: Arc<dyn CommandRunner>,
    ) -> Self {
        Self {
            config,
            repo,
            home,
            brew,
            runner,
        }
    }

    pub fn audit_ids(&self, ids: &[String]) -> Vec<AuditResult> {
        let started = std::time::Instant::now();
        tracing::info!(resource_count = ids.len(), "starting audit");
        let inventory = self.inventory_for(ids);
        let results: Vec<_> = ids
            .iter()
            .filter_map(|id| self.config.resource(id))
            .map(|resource| self.audit(resource, &inventory))
            .collect();
        for result in &results {
            tracing::debug!(
                resource_id = result.id,
                status = %result.status,
                fixable = result.fixable,
                summary = result.summary,
                desired = result.desired,
                actual = result.actual,
                action = ?result.action,
                "resource audited"
            );
        }
        tracing::info!(
            elapsed_ms = started.elapsed().as_millis(),
            issue_count = results
                .iter()
                .filter(|result| !result.status.is_healthy())
                .count(),
            "audit finished"
        );
        results
    }

    pub fn plan_ids(&self, ids: &[String]) -> Vec<PlannedChange> {
        tracing::debug!(resource_count = ids.len(), "building plan");
        let inventory = self.inventory_for(ids);
        let changes: Vec<_> = ids
            .iter()
            .filter_map(|id| self.config.resource(id))
            .filter_map(|resource| {
                let audit = self.audit(resource, &inventory);
                (!audit.status.is_healthy() && audit.fixable).then(|| PlannedChange {
                    id: resource.id.clone(),
                    description: resource.description.clone(),
                    action: self.action(resource),
                })
            })
            .collect();
        for change in &changes {
            tracing::info!(
                resource_id = change.id,
                action = change.action,
                "change planned"
            );
        }
        changes
    }

    pub fn apply_ids<F>(&self, ids: &[String], mut progress: F) -> Vec<(String, Result<()>)>
    where
        F: FnMut(&str),
    {
        let inventory = self.inventory_for(ids);
        ids.iter()
            .filter_map(|id| self.config.resource(id))
            .filter_map(|resource| {
                let audit = self.audit(resource, &inventory);
                if audit.status.is_healthy() {
                    return None;
                }
                if !audit.fixable {
                    return Some((
                        resource.id.clone(),
                        Err(anyhow::anyhow!("{}", audit.summary)),
                    ));
                }
                progress(&format!(
                    "Applying {}: {}",
                    resource.id,
                    self.action(resource)
                ));
                tracing::info!(resource_id = resource.id, action = %self.action(resource), "applying resource");
                let outcome = self.apply(resource);
                match &outcome {
                    Ok(()) => tracing::info!(resource_id = resource.id, "resource applied"),
                    Err(error) => tracing::error!(
                        resource_id = resource.id,
                        error = %format!("{error:#}"),
                        "resource apply failed"
                    ),
                }
                Some((resource.id.clone(), outcome))
            })
            .collect()
    }

    fn inventory_for(&self, ids: &[String]) -> inventory::Inventory {
        let requires_brew = ids
            .iter()
            .filter_map(|id| self.config.resource(id))
            .any(|resource| {
                matches!(
                    resource.kind,
                    ResourceKind::BrewFormula { .. }
                        | ResourceKind::BrewCask { .. }
                        | ResourceKind::BrewService { .. }
                )
            });
        if requires_brew {
            self.inventory(ids)
        } else {
            inventory::Inventory::unavailable()
        }
    }
}
