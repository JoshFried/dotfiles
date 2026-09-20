#![warn(missing_docs)]
//! Audits and reconciles a macOS workstation against a declarative dotfiles manifest.
//!
//! Configuration, inspection, planning, application, presentation, and logging
//! are separated so the same engine can support CLI and TUI workflows.

/// Top-level command orchestration.
pub mod application;
/// Command-line argument definitions.
pub mod cli;
/// Manifest loading and validation.
pub mod config;
/// Terminal-aware semantic styling.
pub mod console;
/// Audit and planning domain types.
pub mod domain;
/// Resource selection, inspection, planning, and application.
pub mod engine;
/// Structured file and terminal logging.
pub mod logging;
/// External command execution abstractions.
pub mod system;
/// Interactive terminal dashboard.
pub mod tui;
