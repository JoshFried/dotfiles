use std::fmt;

use serde::Serialize;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Status {
    Healthy,
    Missing,
    Misplaced,
    Drifted,
    Blocked,
}

impl Status {
    pub fn is_healthy(self) -> bool {
        self == Self::Healthy
    }

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

#[derive(Clone, Debug, Serialize)]
pub struct AuditResult {
    pub id: String,
    pub description: String,
    pub status: Status,
    pub summary: String,
    pub desired: String,
    pub actual: String,
    pub fixable: bool,
    pub action: Option<String>,
}

#[derive(Clone, Debug, Serialize)]
pub struct PlannedChange {
    pub id: String,
    pub description: String,
    pub action: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResourceExplanation {
    pub id: String,
    pub description: String,
    pub tags: Vec<String>,
    pub dependencies: Vec<String>,
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
