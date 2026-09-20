use std::{
    collections::BTreeMap,
    ffi::OsString,
    io,
    path::{Path, PathBuf},
    process::{Command, Stdio},
    time::Instant,
};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CommandRequest {
    pub program: PathBuf,
    pub arguments: Vec<OsString>,
    pub environment: BTreeMap<OsString, OsString>,
}

impl CommandRequest {
    pub fn new(program: impl Into<PathBuf>) -> Self {
        Self {
            program: program.into(),
            arguments: Vec::new(),
            environment: BTreeMap::new(),
        }
    }

    pub fn args<I, S>(mut self, arguments: I) -> Self
    where
        I: IntoIterator<Item = S>,
        S: Into<OsString>,
    {
        self.arguments.extend(arguments.into_iter().map(Into::into));
        self
    }

    pub fn env(mut self, key: impl Into<OsString>, value: impl Into<OsString>) -> Self {
        self.environment.insert(key.into(), value.into());
        self
    }
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct CommandOutput {
    pub success: bool,
    pub stdout: String,
    pub stderr: String,
}

pub trait CommandRunner: Send + Sync {
    fn capture(&self, request: &CommandRequest) -> io::Result<CommandOutput>;
    fn run(&self, request: &CommandRequest) -> io::Result<bool>;
}

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

pub fn find_program(name: &str, path: Option<&std::ffi::OsStr>) -> Option<PathBuf> {
    std::env::split_paths(path.unwrap_or_default())
        .map(|directory| directory.join(name))
        .chain([
            Path::new("/opt/homebrew/bin").join(name),
            Path::new("/usr/local/bin").join(name),
        ])
        .find(|candidate| candidate.is_file())
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
}
