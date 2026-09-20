//! Stable domain values shared by the engine and presentation layers.

use std::fmt;

use serde::Serialize;

/// Health classification for a managed resource.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Status {
    /// Desired and actual state match.
    Healthy,
    /// No corresponding installation or path was found.
    Missing,
    /// The resource exists through an unexpected source or location.
    Misplaced,
    /// The resource exists but differs from the desired state.
    Drifted,
    /// A prerequisite prevents inspection or reconciliation.
    Blocked,
}

impl Status {
    /// Returns whether no corrective action is required.
    pub fn is_healthy(self) -> bool {
        self == Self::Healthy
    }

    /// Returns the compact symbol used by human-readable output.
    pub fn symbol(self) -> &'static str {
        match self {
            Self::Healthy => "●",
            Self::Missing => "○",
            Self::Misplaced => "↪",
            Self::Drifted => "◆",
            Self::Blocked => "!",
        }
    }
}

impl fmt::Display for Status {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let value = match self {
            Self::Healthy => "healthy",
            Self::Missing => "missing",
            Self::Misplaced => "misplaced",
            Self::Drifted => "drifted",
            Self::Blocked => "blocked",
        };
        formatter.write_str(value)
    }
}

/// Complete observed state for one resource.
#[derive(Clone, Debug, Serialize)]
pub struct AuditResult {
    /// Stable resource identifier.
    pub id: String,
    /// Human-readable purpose.
    pub description: String,
    /// Health classification.
    pub status: Status,
    /// Concise explanation of the classification.
    pub summary: String,
    /// Expected state.
    pub desired: String,
    /// Observed state.
    pub actual: String,
    /// Whether the engine can safely reconcile the resource.
    pub fixable: bool,
    /// Proposed operation when automatic reconciliation is available.
    pub action: Option<String>,
}

/// One automatic change proposed by a plan.
#[derive(Clone, Debug, Serialize)]
pub struct PlannedChange {
    /// Stable resource identifier.
    pub id: String,
    /// Human-readable purpose.
    pub description: String,
    /// Command or filesystem operation to perform.
    pub action: String,
}

/// Metadata and dependency relationships for one resource.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResourceExplanation {
    /// Stable resource identifier.
    pub id: String,
    /// Human-readable purpose.
    pub description: String,
    /// Searchable resource categories.
    pub tags: Vec<String>,
    /// Resources that must be handled first.
    pub dependencies: Vec<String>,
    /// Resources that directly depend on this resource.
    pub dependents: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn healthy_is_the_only_non_issue_status() {
        assert!(Status::Healthy.is_healthy());
        for status in [
            Status::Missing,
            Status::Misplaced,
            Status::Drifted,
            Status::Blocked,
        ] {
            assert!(!status.is_healthy());
        }
    }

    #[test]
    fn statuses_have_stable_machine_and_human_representations() {
        assert_eq!(Status::Missing.to_string(), "missing");
        assert_eq!(Status::Misplaced.symbol(), "↪");
        assert_eq!(
            serde_json::to_string(&Status::Blocked).unwrap(),
            "\"blocked\""
        );
    }
}
