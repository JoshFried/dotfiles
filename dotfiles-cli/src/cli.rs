use std::path::PathBuf;

use anstyle::AnsiColor;
use clap::{ArgAction, Args, Parser, Subcommand};

const CLAP_STYLES: clap::builder::styling::Styles = clap::builder::styling::Styles::styled()
    .header(AnsiColor::BrightBlue.on_default().bold().underline())
    .usage(AnsiColor::BrightBlue.on_default().bold().underline())
    .literal(AnsiColor::BrightCyan.on_default().bold())
    .placeholder(AnsiColor::BrightYellow.on_default())
    .error(AnsiColor::BrightRed.on_default().bold())
    .valid(AnsiColor::BrightGreen.on_default())
    .invalid(AnsiColor::BrightYellow.on_default());

#[derive(Debug, Parser)]
#[command(
    name = "dotfiles",
    version,
    about = "Audit, understand, and apply this machine's dotfiles",
    long_about = "Audit, understand, and apply this machine's dotfiles.\n\nRun without a command to open the interactive dashboard.",
    color = clap::ColorChoice::Auto,
    styles = CLAP_STYLES,
    next_line_help = true,
    subcommand_help_heading = "COMMANDS",
    next_help_heading = "GLOBAL OPTIONS",
    after_help = "Examples:\n  dotfiles                     Open the interactive dashboard\n  dotfiles audit               Report configuration drift\n  dotfiles plan --profile core Preview changes for the core profile\n  dotfiles apply --tag service Apply service-related changes\n  dotfiles explain symlink.zshrc"
)]
pub struct Cli {
    #[arg(
        long,
        global = true,
        value_name = "PATH",
        help = "Use a different dotfiles repository"
    )]
    pub repo: Option<PathBuf>,

    #[arg(
        long,
        global = true,
        value_name = "PATH",
        help = "Use a different configuration manifest"
    )]
    pub config: Option<PathBuf>,

    #[arg(
        short,
        long,
        global = true,
        action = ArgAction::Count,
        help = "Increase terminal log verbosity (-v info, -vv debug, -vvv trace)"
    )]
    pub verbose: u8,

    #[arg(
        long,
        global = true,
        value_name = "DIRECTORY",
        help = "Write structured logs to this directory"
    )]
    pub log_directory: Option<PathBuf>,

    #[command(subcommand)]
    pub command: Option<Command>,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    /// Open the interactive audit and apply dashboard
    Tui(FilterArgs),
    /// Report the current state without making changes
    Audit {
        #[command(flatten)]
        filter: FilterArgs,
        #[arg(long, help = "Emit machine-readable JSON without colors")]
        json: bool,
    },
    /// Show the changes needed to reach the desired state
    Plan(FilterArgs),
    /// Apply selected changes
    Apply {
        #[command(flatten)]
        filter: FilterArgs,
        #[arg(long, help = "Skip the confirmation prompt")]
        yes: bool,
    },
    /// List configured resources and profiles
    List,
    /// Explain a resource and its dependencies
    Explain {
        #[arg(value_name = "RESOURCE")]
        id: String,
    },
}

#[derive(Args, Clone, Debug, Default)]
pub struct FilterArgs {
    #[arg(
        long,
        value_name = "PROFILE",
        help = "Select every resource in a profile"
    )]
    pub profile: Vec<String>,

    #[arg(long, value_name = "TAG", help = "Select every resource with a tag")]
    pub tag: Vec<String>,

    #[arg(value_name = "RESOURCE", help = "Select specific resource IDs")]
    pub resources: Vec<String>,
}

#[cfg(test)]
mod tests {
    use clap::Parser;

    use super::*;

    #[test]
    fn defaults_to_tui_when_no_subcommand_is_present() {
        let cli = Cli::try_parse_from(["dotfiles"]).unwrap();
        assert!(cli.command.is_none());
        assert_eq!(cli.verbose, 0);
    }

    #[test]
    fn parses_audit_filters_with_derive_api() {
        let cli = Cli::try_parse_from([
            "dotfiles",
            "audit",
            "--profile",
            "desktop",
            "--tag",
            "service",
            "--json",
            "service.sketchybar",
        ])
        .unwrap();

        let Some(Command::Audit { filter, json }) = cli.command else {
            panic!("expected audit command");
        };
        assert!(json);
        assert_eq!(filter.profile, ["desktop"]);
        assert_eq!(filter.tag, ["service"]);
        assert_eq!(filter.resources, ["service.sketchybar"]);
    }

    #[test]
    fn rejects_unknown_subcommands() {
        assert!(Cli::try_parse_from(["dotfiles", "destroy"]).is_err());
    }

    #[test]
    fn parses_apply_confirmation_override() {
        let cli = Cli::try_parse_from(["dotfiles", "apply", "--yes", "symlink.zshrc"]).unwrap();
        let Some(Command::Apply { filter, yes }) = cli.command else {
            panic!("expected apply command");
        };
        assert!(yes);
        assert_eq!(filter.resources, ["symlink.zshrc"]);
    }

    #[test]
    fn counts_verbosity_flags() {
        let cli = Cli::try_parse_from(["dotfiles", "-vvv", "list"]).unwrap();
        assert_eq!(cli.verbose, 3);
    }
}
