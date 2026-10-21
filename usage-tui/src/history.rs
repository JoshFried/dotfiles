use std::collections::{HashMap, VecDeque};

use crate::memory::Snapshot;

const SAMPLES: usize = 120;

#[derive(Clone, Debug)]
pub struct Trend {
    pub first: u64,
    pub values: VecDeque<u64>,
    seen: u64,
}

impl Trend {
    pub fn recent(&self, count: usize) -> Vec<u64> {
        self.values
            .iter()
            .skip(self.values.len().saturating_sub(count))
            .copied()
            .collect()
    }

    pub fn change(&self) -> i128 {
        i128::from(*self.values.back().unwrap_or(&self.first)) - i128::from(self.first)
    }

    pub fn label(&self) -> String {
        let change = self.change();
        if change == 0 {
            "unchanged since first sample".into()
        } else {
            format!(
                "{}{} since first sample",
                if change > 0 { "+" } else { "−" },
                crate::bytes(change.unsigned_abs() as u64)
            )
        }
    }
}

#[derive(Default)]
pub struct History {
    trends: HashMap<String, Trend>,
    sequence: u64,
}

impl History {
    pub fn record(&mut self, snapshot: &Snapshot) {
        self.sequence += 1;
        for app in &snapshot.apps {
            self.push(&app.id, app.resident);
            for process in &app.processes {
                self.push(&process.id(), process.resident);
            }
        }
        if let Some(breakdown) = &snapshot.breakdown {
            for category in &breakdown.categories {
                self.push(&format!("system:{}", category.name), category.bytes);
            }
        }
        self.trends.retain(|_, trend| trend.seen == self.sequence);
    }

    fn push(&mut self, id: &str, size: u64) {
        let trend = self.trends.entry(id.into()).or_insert_with(|| Trend {
            first: size,
            values: VecDeque::new(),
            seen: self.sequence,
        });
        if trend.values.len() == SAMPLES {
            trend.values.pop_front();
        }
        trend.values.push_back(size);
        trend.seen = self.sequence;
    }

    pub fn get(&self, id: &str) -> Option<&Trend> {
        self.trends.get(id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn history_is_bounded_and_keeps_original_baseline() {
        let mut history = History::default();
        for size in 0..200 {
            history.push("app", size);
        }
        let trend = history.get("app").unwrap();
        assert_eq!(trend.values.len(), SAMPLES);
        assert_eq!(trend.first, 0);
        assert_eq!(trend.change(), 199);
        assert_eq!(trend.recent(4), vec![196, 197, 198, 199]);
        assert!(trend.label().starts_with("+199 B"));
        history.push("app", 0);
        assert!(history.get("app").unwrap().label().starts_with("unchanged"));
    }
}
