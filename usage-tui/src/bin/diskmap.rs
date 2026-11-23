//! Parse the starting directory and allocated or apparent byte mode, then
//! launch the shared application with a disk scan.

use clap::Parser;
use std::path::PathBuf;

#[derive(Parser)]
#[command(about = "Explore disk usage with a Kanagawa treemap")]
struct Args {
    #[arg(default_value = ".")]
    path: PathBuf,
    #[arg(long, help = "Start with apparent bytes instead of allocated bytes")]
    apparent: bool,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    usage_tui::app::run(usage_tui::app::AppState::disk(args.path, args.apparent)?)
}
