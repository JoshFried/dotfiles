use clap::{Parser, ValueEnum};
use std::time::Duration;

#[derive(Clone, Copy, ValueEnum)]
enum View {
    Apps,
    System,
}

#[derive(Parser)]
#[command(about = "Explore live memory usage with a Kanagawa treemap")]
struct Args {
    #[arg(long, default_value = "2", value_parser = parse_interval)]
    interval: f64,
    #[arg(long, value_enum, default_value = "apps")]
    view: View,
}

fn parse_interval(value: &str) -> Result<f64, String> {
    let seconds: f64 = value
        .parse()
        .map_err(|_| "Interval must be a number of seconds")?;
    if !seconds.is_finite() || !(0.1..=86_400.0).contains(&seconds) {
        return Err("Interval must be between 0.1 and 86400 seconds".into());
    }
    Ok(seconds)
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    usage_tui::app::run(usage_tui::app::AppState::memory(
        Duration::from_secs_f64(args.interval),
        matches!(args.view, View::System),
    ))
}
