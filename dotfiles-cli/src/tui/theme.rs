//! Kanagawa-inspired semantic colors for dashboard widgets.

use ratatui::style::{Color, Modifier, Style};

use crate::domain::Status;

pub const BACKGROUND_HIGHLIGHT: Color = Color::Rgb(42, 42, 55);
pub const BLUE: Color = Color::Rgb(126, 156, 216);
pub const DIM: Color = Color::Rgb(114, 113, 105);
pub const FOREGROUND: Color = Color::Rgb(220, 215, 186);
pub const GREEN: Color = Color::Rgb(152, 187, 108);
pub const RED: Color = Color::Rgb(228, 104, 118);
pub const VIOLET: Color = Color::Rgb(149, 127, 184);
pub const YELLOW: Color = Color::Rgb(230, 195, 132);

pub fn identity() -> Style {
    Style::default().fg(BLUE).add_modifier(Modifier::BOLD)
}

pub fn secondary() -> Style {
    Style::default().fg(DIM)
}

pub fn selected() -> Style {
    Style::default()
        .fg(FOREGROUND)
        .bg(BACKGROUND_HIGHLIGHT)
        .add_modifier(Modifier::BOLD)
}

pub fn status(status: Status) -> Style {
    let color = match status {
        Status::Healthy => GREEN,
        Status::Missing => YELLOW,
        Status::Misplaced => VIOLET,
        Status::Drifted | Status::Blocked => RED,
    };
    let style = Style::default().fg(color);
    if status == Status::Blocked {
        style.add_modifier(Modifier::BOLD)
    } else {
        style
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn primary_status_categories_are_visually_distinct() {
        let colors = [
            status(Status::Healthy).fg,
            status(Status::Missing).fg,
            status(Status::Misplaced).fg,
            status(Status::Drifted).fg,
        ];

        for (index, color) in colors.iter().enumerate() {
            assert!(!colors[index + 1..].contains(color));
        }
    }

    #[test]
    fn blocked_status_adds_emphasis_to_failure_color() {
        assert_eq!(status(Status::Blocked).fg, Some(RED));
        assert!(
            status(Status::Blocked)
                .add_modifier
                .contains(Modifier::BOLD)
        );
    }
}
