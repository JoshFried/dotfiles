//! Process entry point for the `dotfiles` executable.

use std::process::ExitCode;

use clap::Parser;
use dotfiles_cli::{application, cli::Cli, console::Console};

fn main() -> ExitCode {
    match application::run(Cli::parse()) {
        Ok(code) => ExitCode::from(code),
        Err(error) => {
            let console = Console::detect_stderr();
            eprintln!("{}: {error:#}", console.error("error"));
            ExitCode::FAILURE
        }
    }
}
