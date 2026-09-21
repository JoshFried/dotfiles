//! Injectable external-command execution and executable discovery.

use std::{
    collections::BTreeMap,
    ffi::OsString,
    io,
    os::unix::fs::PermissionsExt,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    time::Instant,
};

/// Immutable description of an external command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CommandRequest {
    /// Executable name or path.
    pub program: PathBuf,
    /// Ordered process arguments.
    pub arguments: Vec<OsString>,
    /// Environment variables added or replaced for the child.
    pub environment: BTreeMap<OsString, OsString>,
}

impl CommandRequest {
    /// Creates a request for an executable with no arguments or environment overrides.
    pub fn new(program: impl Into<PathBuf>) -> Self {
        Self {
            program: program.into(),
            arguments: Vec::new(),
            environment: BTreeMap::new(),
        }
    }

    /// Appends process arguments.
    pub fn args<I, S>(mut self, arguments: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: Into<OsString>,
    {
        self.arguments.extend(arguments.into_iter().map(Into::into));
        self
    }

    /// Adds or replaces one child-process environment variable.
    pub fn env(mut self, key: impl Into<OsString>, value: impl Into<OsString>) -> Self {
        self.environment.insert(key.into(), value.into());
        self
    }
}

/// Captured process status and text streams.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct CommandOutput {
    /// Whether the process exited successfully.
    pub success: bool,
    /// Standard output decoded lossily as UTF-8.
    pub stdout: String,
    /// Standard error decoded lossily as UTF-8.
    pub stderr: String,
}

/// Execution boundary used to isolate subprocesses in tests.
pub trait CommandRunner: Send + Sync {
    /// Runs a command with both output streams captured.
    fn capture(&self, request: &CommandRequest) -> io::Result<CommandOutput>;
    /// Runs a command attached to the current terminal and returns its success status.
    fn run(&self, request: &CommandRequest) -> io::Result<bool>;
}

/// Command runner backed by [`std::process::Command`].
#[derive(Debug, Default)]
pub struct SystemCommandRunner;

impl CommandRunner for SystemCommandRunner {
    fn capture(&self, request: &CommandRequest) -> io::Result<CommandOutput> {
        let started = Instant::now();
        tracing::debug!(
            program = %request.program.display(),
            arguments = ?request.arguments,
            environment_keys = ?request.environment.keys().collect::<Vec<_>>(),
            mode = "capture",
            "starting command"
        );
        let output = command(request)
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output();
        let output = match output {
            Ok(output) => output,
            Err(error) => {
                tracing::error!(
                    program = %request.program.display(),
                    elapsed_ms = started.elapsed().as_millis(),
                    error = %error,
                    "command failed to start"
                );
                return Err(error);
            }
        };
        let result = CommandOutput {
            success: output.status.success(),
            stdout: String::from_utf8_lossy(&output.stdout).into_owned(),
            stderr: String::from_utf8_lossy(&output.stderr).into_owned(),
        };
        tracing::debug!(
            program = %request.program.display(),
            success = result.success,
            elapsed_ms = started.elapsed().as_millis(),
            "command completed"
        );
        tracing::trace!(
            program = %request.program.display(),
            stdout = result.stdout,
            stderr = result.stderr,
            "command output"
        );
        Ok(result)
    }

    fn run(&self, request: &CommandRequest) -> io::Result<bool> {
        let started = Instant::now();
        tracing::info!(
            program = %request.program.display(),
            arguments = ?request.arguments,
            environment_keys = ?request.environment.keys().collect::<Vec<_>>(),
            mode = "interactive",
            "starting command"
        );
        let result = command(request).status().map(|status| status.success());
        match &result {
            Ok(success) => tracing::info!(
                program = %request.program.display(),
                success,
                elapsed_ms = started.elapsed().as_millis(),
                "command completed"
            ),
            Err(error) => tracing::error!(
                program = %request.program.display(),
                elapsed_ms = started.elapsed().as_millis(),
                error = %error,
                "command failed to start"
            ),
        }
        result
    }
}

fn command(request: &CommandRequest) -> Command {
    let mut command = Command::new(&request.program);
    command.args(&request.arguments).envs(&request.environment);
    command
}

/// Locates an executable on `PATH` or in common system prefixes.
pub fn find_program(name: &str, path: Option<&std::ffi::OsStr>) -> Option<PathBuf> {
    find_program_with_home(name, path, None)
}

/// Locates an executable on `PATH` and in common user and system bin directories.
pub fn find_program_with_home(
    name: &str,
    path: Option<&std::ffi::OsStr>,
    home: Option<&Path>,
) -> Option<PathBuf> {
    std::env::split_paths(path.unwrap_or_default())
        .map(|directory| directory.join(name))
        .chain(home.into_iter().flat_map(|home| {
            [
                home.join(".local/bin").join(name),
                home.join(".cargo/bin").join(name),
                home.join("go/bin").join(name),
                home.join("bin").join(name),
            ]
        }))
        .chain([
            Path::new("/opt/homebrew/bin").join(name),
            Path::new("/usr/local/bin").join(name),
        ])
        .find(|candidate| {
            candidate.metadata().is_ok_and(|metadata| {
                metadata.is_file() && metadata.permissions().mode() & 0o111 != 0
            })
        })
}

#[cfg(test)]
mod tests {
    use std::{fs, os::unix::fs::PermissionsExt};

    use tempfile::tempdir;

    use super::*;

    #[test]
    fn command_request_builds_arguments_and_environment() {
        let request = CommandRequest::new("brew")
            .args(["list", "--formula"])
            .env("HOMEBREW_NO_AUTO_UPDATE", "1");
        assert_eq!(request.program, PathBuf::from("brew"));
        assert_eq!(request.arguments, ["list", "--formula"]);
        assert_eq!(
            request
                .environment
                .get(std::ffi::OsStr::new("HOMEBREW_NO_AUTO_UPDATE")),
            Some(&OsString::from("1"))
        );
    }

    #[test]
    fn finds_executables_on_the_supplied_path() {
        let directory = tempdir().unwrap();
        let executable = directory.path().join("tool");
        fs::write(&executable, "#!/bin/sh\n").unwrap();
        fs::set_permissions(&executable, fs::Permissions::from_mode(0o755)).unwrap();

        let found = find_program("tool", Some(directory.path().as_os_str()));

        assert_eq!(found, Some(executable));
    }

    #[test]
    fn reports_missing_executables() {
        let directory = tempdir().unwrap();
        assert_eq!(
            find_program(
                "definitely-not-a-real-command",
                Some(directory.path().as_os_str())
            ),
            None
        );
    }

    #[test]
    fn ignores_files_without_execute_permissions() {
        let directory = tempdir().unwrap();
        fs::write(directory.path().join("tool"), "not executable").unwrap();

        let found = find_program("tool", Some(directory.path().as_os_str()));

        assert_eq!(found, None);
    }

    #[test]
    fn finds_executables_in_common_user_bin_directories() {
        let home = tempdir().unwrap();
        let cargo_bin = home.path().join(".cargo/bin");
        fs::create_dir_all(&cargo_bin).unwrap();
        let executable = cargo_bin.join("tool");
        fs::write(&executable, "#!/bin/sh\n").unwrap();
        fs::set_permissions(&executable, fs::Permissions::from_mode(0o755)).unwrap();

        let found = find_program_with_home("tool", None, Some(home.path()));

        assert_eq!(found, Some(executable));
    }
}
