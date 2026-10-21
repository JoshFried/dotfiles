pub mod app;
pub mod chrome;
pub mod clipboard;
pub mod disk;
pub mod events;
pub mod history;
pub mod memory;
pub mod terminal;
pub mod theme;
pub mod treemap;

pub fn bytes(value: u64) -> String {
    const UNITS: [&str; 6] = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
    let mut amount = value as f64;
    let mut unit = 0;
    while amount >= 1024.0 && unit < UNITS.len() - 1 {
        amount /= 1024.0;
        unit += 1;
    }
    if unit == 0 {
        format!("{value} B")
    } else {
        format!("{amount:.1} {}", UNITS[unit])
    }
}

pub fn fuzzy_match(name: &str, query: &str) -> bool {
    let name = name.to_lowercase();
    let mut chars = name.chars();
    query
        .to_lowercase()
        .chars()
        .all(|needle| chars.any(|c| c == needle))
}
