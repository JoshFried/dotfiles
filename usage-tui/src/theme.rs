use ratatui::style::Color;

pub const BACKGROUND: Color = Color::Rgb(31, 31, 40);
pub const SEPARATOR: Color = Color::Rgb(42, 42, 55);
pub const FOREGROUND: Color = Color::Rgb(220, 215, 186);
pub const DIM: Color = Color::Rgb(114, 113, 105);
pub const SELECTED: Color = Color::Rgb(230, 195, 132);
pub const INK: Color = Color::Rgb(22, 22, 29);
pub const BLUE: Color = Color::Rgb(126, 156, 216);
pub const VIOLET: Color = Color::Rgb(149, 127, 184);
pub const GREEN: Color = Color::Rgb(152, 187, 108);
pub const RED: Color = Color::Rgb(228, 104, 118);
pub const BORDER: Color = Color::Rgb(54, 54, 70);
pub const FILLS: [Color; 7] = [
    Color::Rgb(126, 156, 216),
    Color::Rgb(149, 127, 184),
    Color::Rgb(118, 148, 106),
    Color::Rgb(192, 163, 110),
    Color::Rgb(195, 64, 67),
    Color::Rgb(106, 149, 137),
    Color::Rgb(147, 138, 169),
];

pub fn color(identity: &str) -> Color {
    let hash = identity
        .as_bytes()
        .iter()
        .fold(0xcbf29ce484222325u64, |hash, byte| {
            (hash ^ u64::from(*byte)).wrapping_mul(0x100000001b3)
        });
    FILLS[hash as usize % FILLS.len()]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn color_is_stable_and_in_palette() {
        assert_eq!(
            color("/Applications/Terminal.app"),
            color("/Applications/Terminal.app")
        );
        assert!(FILLS.contains(&color("λ")));
        assert_eq!(color("hello"), FILLS[5]);
    }
}
