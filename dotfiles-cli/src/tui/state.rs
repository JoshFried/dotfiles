//! Mutable dashboard state and visible-resource filtering.

use std::collections::BTreeSet;

use crate::domain::AuditResult;

pub(super) struct App {
    pub results: Vec<AuditResult>,
    pub selected: BTreeSet<String>,
    pub cursor: usize,
    pub show_healthy: bool,
    pub confirming: bool,
    pub searching: bool,
    pub query: String,
    pub message: String,
}

impl App {
    pub fn new(results: Vec<AuditResult>) -> Self {
        let selected = results
            .iter()
            .filter(|result| !result.status.is_healthy() && result.fixable)
            .map(|result| result.id.clone())
            .collect();
        Self {
            results,
            selected,
            cursor: 0,
            show_healthy: false,
            confirming: false,
            searching: false,
            query: String::new(),
            message: "Audit complete".to_owned(),
        }
    }

    pub fn visible(&self) -> Vec<usize> {
        let query = self.query.to_ascii_lowercase();
        self.results
            .iter()
            .enumerate()
            .filter(|(_, result)| {
                let status_matches = self.show_healthy || !result.status.is_healthy();
                let query_matches = query.is_empty()
                    || result.id.to_ascii_lowercase().contains(&query)
                    || result.description.to_ascii_lowercase().contains(&query)
                    || result.summary.to_ascii_lowercase().contains(&query);
                status_matches && query_matches
            })
            .map(|(index, _)| index)
            .collect()
    }

    pub fn current(&self) -> Option<&AuditResult> {
        self.visible()
            .get(self.cursor)
            .and_then(|index| self.results.get(*index))
    }

    pub fn clamp_cursor(&mut self) {
        let length = self.visible().len();
        self.cursor = if length == 0 {
            0
        } else {
            self.cursor.min(length - 1)
        };
    }
}

#[cfg(test)]
mod tests {
    use crate::domain::{AuditResult, Status};

    use super::*;

    fn result(id: &str, status: Status, fixable: bool) -> AuditResult {
        AuditResult {
            id: id.to_owned(),
            description: format!("{id} description"),
            status,
            summary: format!("{id} summary"),
            desired: String::new(),
            actual: String::new(),
            fixable,
            action: None,
        }
    }

    #[test]
    fn fixable_issues_are_selected_initially() {
        let app = App::new(vec![
            result("healthy", Status::Healthy, false),
            result("fixable", Status::Missing, true),
            result("manual", Status::Blocked, false),
        ]);
        assert_eq!(app.selected, BTreeSet::from(["fixable".to_owned()]));
    }

    #[test]
    fn healthy_resources_are_hidden_initially() {
        let app = App::new(vec![
            result("healthy", Status::Healthy, false),
            result("missing", Status::Missing, true),
        ]);
        assert_eq!(app.visible(), [1]);
    }

    #[test]
    fn showing_healthy_resources_preserves_order() {
        let mut app = App::new(vec![
            result("healthy", Status::Healthy, false),
            result("missing", Status::Missing, true),
        ]);
        app.show_healthy = true;
        assert_eq!(app.visible(), [0, 1]);
    }

    #[test]
    fn search_matches_ids_descriptions_and_summaries() {
        let mut app = App::new(vec![
            result("formula.ripgrep", Status::Missing, true),
            result("service.sketchybar", Status::Drifted, true),
        ]);
        app.query = "SKETCHY".to_owned();
        assert_eq!(app.visible(), [1]);
    }

    #[test]
    fn cursor_is_clamped_after_filtering() {
        let mut app = App::new(vec![
            result("one", Status::Missing, true),
            result("two", Status::Missing, true),
        ]);
        app.cursor = 1;
        app.query = "one".to_owned();
        app.clamp_cursor();
        assert_eq!(app.cursor, 0);
    }
}
