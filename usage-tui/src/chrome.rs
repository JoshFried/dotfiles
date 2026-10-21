use crate::theme;
use ratatui::{
    style::{Color, Modifier, Style},
    text::{Line, Span},
};

pub fn badge(text: impl Into<String>, color: Color) -> Span<'static> {
    Span::styled(
        format!(" {} ", text.into()),
        Style::default()
            .fg(color)
            .bg(theme::SEPARATOR)
            .add_modifier(Modifier::BOLD),
    )
}

pub struct Hint {
    pub key: &'static str,
    pub label: String,
    pub color: Color,
}

impl Hint {
    pub fn new(key: &'static str, label: impl Into<String>, color: Color) -> Self {
        Self {
            key,
            label: label.into(),
            color,
        }
    }
}

pub fn legend(hints: &[Hint], width: u16) -> Line<'static> {
    let mut spans = Vec::new();
    let mut used = 0;
    for hint in hints {
        let key = badge(hint.key, hint.color);
        let description = Span::styled(
            format!(" {}  ", hint.label),
            Style::default().fg(theme::FOREGROUND),
        );
        let size = key.width() + description.width();
        if used + size > usize::from(width) {
            continue;
        }
        used += size;
        spans.extend([key, description]);
    }
    Line::from(spans)
}

pub fn help(disk: bool) -> Vec<Line<'static>> {
    let mut rows = vec![
        (
            "hjkl / arrows",
            "Move between tiles or list entries",
            theme::BLUE,
        ),
        (
            "enter",
            "Open folder, collection, app, or details",
            theme::GREEN,
        ),
        (
            "ctrl+o",
            if disk {
                "Back / parent folder; Backspace also works"
            } else {
                "Previous view; Backspace also works"
            },
            theme::BLUE,
        ),
        ("tab", "Switch map / list focus", theme::VIOLET),
        (
            "gg / G",
            "First / last entry; Home / End also work",
            theme::BLUE,
        ),
        ("pgup / pgdn", "Move one page in the list", theme::BLUE),
        (
            "/",
            "Fuzzy search; Enter applies, Esc restores",
            theme::SELECTED,
        ),
        (
            "s",
            "Switch size descending / name ascending",
            theme::SELECTED,
        ),
        (
            "b",
            "Toggle balanced / proportional tile sizing",
            theme::VIOLET,
        ),
        (
            "y",
            "Copy the selected file / executable path",
            theme::GREEN,
        ),
        (
            "r",
            if disk {
                "Rescan the scan root"
            } else {
                "Fresh sample, size sort, and fresh layout"
            },
            theme::GREEN,
        ),
    ];
    if disk {
        rows.extend([
            ("a", "Toggle allocated / apparent bytes", theme::SELECTED),
            ("d", "Move to Trash; y confirms, n cancels", theme::RED),
        ]);
    } else {
        rows.extend([
            ("v", "Switch Apps / System memory", theme::VIOLET),
            ("space", "Pause / resume samples", theme::SELECTED),
        ]);
    }
    rows.extend([
        ("esc", "Clear filter / close dialog", theme::SELECTED),
        ("? / q", "Help / quit (Ctrl+C also quits)", theme::BLUE),
    ]);
    let mut lines = vec![
        Line::from(Span::styled(
            " Explore · inspect · navigate",
            Style::default()
                .fg(theme::VIOLET)
                .add_modifier(Modifier::BOLD),
        )),
        Line::default(),
    ];
    lines.extend(rows.into_iter().map(|(key, description, color)| {
        Line::from(vec![
            badge(format!("{key:<13}"), color),
            Span::raw(format!(" {description}")),
        ])
    }));
    lines.push(Line::default());
    for note in if disk {
        [
            "Scanning totals are provisional. Trash waits until scanning finishes.",
            "Allocated usage is an estimate; hidden and zero-byte entries stay in the list.",
        ]
    } else {
        [
            "History keeps 120 samples; growth is measured since first observation.",
            "Shared pages may count more than once. Small changes keep tiles steady.",
        ]
    } {
        lines.push(Line::from(Span::styled(
            note,
            Style::default().fg(theme::DIM),
        )));
    }
    lines
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hints_fit_as_complete_colored_units() {
        let hints = [
            Hint::new("q", "quit", theme::RED),
            Hint::new("enter", "open", theme::BLUE),
        ];
        let line = legend(&hints, 12);
        assert!(line.width() <= 12);
        assert_eq!(line.to_string(), " q  quit  ");
        assert_eq!(line.spans[0].style.fg, Some(theme::RED));
        assert_eq!(line.spans[0].style.bg, Some(theme::SEPARATOR));
    }
}
