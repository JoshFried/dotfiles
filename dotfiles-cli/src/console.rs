//! Semantic ANSI styling that respects terminal capabilities and color conventions.

use std::{env, fmt::Display, io::IsTerminal};

use anstyle::{AnsiColor, Effects, Style};

use crate::domain::Status;

/// Styles human-readable output when its destination supports color.
#[derive(Clone, Copy, Debug)]
pub struct Console {
    color: bool,
}

impl Console {
    /// Detects whether standard output should use ANSI styling.
    pub fn detect() -> Self {
        Self {
            color: color_enabled(std::io::stdout().is_terminal()),
        }
    }

    /// Detects whether standard error should use ANSI styling.
    pub fn detect_stderr() -> Self {
        Self {
            color: color_enabled(std::io::stderr().is_terminal()),
        }
    }

    /// Returns whether this console emits ANSI styling.
    pub fn color_enabled(&self) -> bool {
        self.color
    }

    /// Renders a value with the supplied style when color is enabled.
    pub fn paint(&self, style: Style, value: impl Display) -> String {
        if self.color {
            format!("{}{}{}", style.render(), value, style.render_reset())
        } else {
            value.to_string()
        }
    }

    /// Styles a value according to an audit status.
    pub fn status(&self, status: Status, value: impl Display) -> String {
        self.paint(status_style(status), value)
    }

    /// Styles a resource identity or interactive control.
    pub fn identity(&self, value: impl Display) -> String {
        self.paint(blue().effects(Effects::BOLD), value)
    }

    /// Styles a successful outcome.
    pub fn success(&self, value: impl Display) -> String {
        self.paint(green().effects(Effects::BOLD), value)
    }

    /// Styles a warning or pending decision.
    pub fn warning(&self, value: impl Display) -> String {
        self.paint(yellow().effects(Effects::BOLD), value)
    }

    /// Styles a failed or blocked outcome.
    pub fn error(&self, value: impl Display) -> String {
        self.paint(red().effects(Effects::BOLD), value)
    }

    /// Styles secondary diagnostic detail.
    pub fn detail(&self, value: impl Display) -> String {
        self.paint(Style::new().effects(Effects::DIMMED), value)
    }

    /// Styles an action that has not yet been applied.
    pub fn planned_action(&self, value: impl Display) -> String {
        self.paint(yellow(), value)
    }
}

fn color_enabled(is_terminal: bool) -> bool {
    if env::var_os("NO_COLOR").is_some() {
        return false;
    }
    let forced = ["CLICOLOR_FORCE", "FORCE_COLOR"]
        .iter()
        .filter_map(|name| env::var(name).ok())
        .any(|value| !value.is_empty() && value != "0");
    forced || (is_terminal && !env::var("TERM").is_ok_and(|term| term == "dumb"))
}

fn status_style(status: Status) -> Style {
    match status {
        Status::Healthy => green(),
        Status::Missing => yellow(),
        Status::Misplaced => violet(),
        Status::Drifted => red(),
        Status::Blocked => red().effects(Effects::BOLD),
    }
}

fn blue() -> Style {
    Style::new().fg_color(Some(AnsiColor::BrightBlue.into()))
}

fn green() -> Style {
    Style::new().fg_color(Some(AnsiColor::BrightGreen.into()))
}

fn yellow() -> Style {
    Style::new().fg_color(Some(AnsiColor::BrightYellow.into()))
}

fn violet() -> Style {
    Style::new().fg_color(Some(AnsiColor::BrightMagenta.into()))
}

fn red() -> Style {
    Style::new().fg_color(Some(AnsiColor::BrightRed.into()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn disabled_console_returns_plain_text() {
        let console = Console { color: false };
        assert_eq!(console.success("healthy"), "healthy");
    }

    #[test]
    fn enabled_console_wraps_text_in_ansi_sequences() {
        let console = Console { color: true };
        let rendered = console.error("failed");
        assert!(rendered.starts_with("\u{1b}["));
        assert!(rendered.contains("failed"));
        assert!(rendered.ends_with("\u{1b}[0m"));
    }

    #[test]
    fn every_status_has_a_distinct_visual_representation() {
        let console = Console { color: true };
        let rendered: std::collections::BTreeSet<_> = [
            Status::Healthy,
            Status::Missing,
            Status::Misplaced,
            Status::Drifted,
            Status::Blocked,
        ]
        .map(|status| console.status(status, "state"))
        .into_iter()
        .collect();
        assert_eq!(rendered.len(), 5);
    }
}
