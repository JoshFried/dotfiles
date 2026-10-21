#![cfg(unix)]

use std::{
    fs::File,
    io::{self, Read, Write},
    os::{
        fd::{AsRawFd, FromRawFd},
        unix::process::CommandExt,
    },
    process::{Child, Command, Stdio},
    thread,
    time::{Duration, Instant},
};

struct Pty {
    child: Child,
    master: File,
    slave: File,
    original: libc::termios,
    output: Vec<u8>,
}

impl Pty {
    fn start(mut command: Command) -> Self {
        unsafe {
            let mut master = -1;
            let mut slave = -1;
            let mut size = libc::winsize {
                ws_row: 28,
                ws_col: 110,
                ws_xpixel: 0,
                ws_ypixel: 0,
            };
            assert_eq!(
                libc::openpty(
                    &mut master,
                    &mut slave,
                    std::ptr::null_mut(),
                    std::ptr::null_mut(),
                    &raw mut size
                ),
                0,
                "{}",
                io::Error::last_os_error()
            );
            let master = File::from_raw_fd(master);
            let slave = File::from_raw_fd(slave);
            let mut original = std::mem::zeroed();
            assert_eq!(libc::tcgetattr(slave.as_raw_fd(), &mut original), 0);
            let flags = libc::fcntl(master.as_raw_fd(), libc::F_GETFL);
            assert_eq!(
                libc::fcntl(master.as_raw_fd(), libc::F_SETFL, flags | libc::O_NONBLOCK),
                0
            );
            command
                .stdin(Stdio::from(slave.try_clone().unwrap()))
                .stdout(Stdio::from(slave.try_clone().unwrap()))
                .stderr(Stdio::from(slave.try_clone().unwrap()))
                .env("TERM", "xterm-256color")
                .env("COLORTERM", "truecolor")
                .env_remove("NO_COLOR");
            command.pre_exec(|| {
                if libc::setsid() < 0 {
                    return Err(io::Error::last_os_error());
                }
                Ok(())
            });
            let child = command.spawn().unwrap();
            Self {
                child,
                master,
                slave,
                original,
                output: Vec::new(),
            }
        }
    }

    fn drain(&mut self) {
        let mut buffer = [0; 65_536];
        loop {
            match self.master.read(&mut buffer) {
                Ok(0) => break,
                Ok(count) => self.output.extend_from_slice(&buffer[..count]),
                Err(error)
                    if error.kind() == io::ErrorKind::WouldBlock
                        || error.raw_os_error() == Some(libc::EIO) =>
                {
                    break;
                }
                Err(error) => panic!("{error}"),
            }
        }
    }

    fn wait_for(&mut self, text: &[u8]) {
        let deadline = Instant::now() + Duration::from_secs(5);
        loop {
            self.drain();
            if self.output.windows(text.len()).any(|window| window == text) {
                return;
            }
            assert!(
                Instant::now() < deadline,
                "Missing {:?} in {}",
                String::from_utf8_lossy(text),
                String::from_utf8_lossy(&self.output)
            );
            thread::sleep(Duration::from_millis(5));
        }
    }

    fn keys(&mut self, keys: &[u8]) {
        self.master.write_all(keys).unwrap();
    }

    fn finish(&mut self, success: bool) {
        let deadline = Instant::now() + Duration::from_secs(5);
        loop {
            self.drain();
            if let Some(status) = self.child.try_wait().unwrap() {
                assert_eq!(
                    status.success(),
                    success,
                    "{}",
                    String::from_utf8_lossy(&self.output)
                );
                break;
            }
            assert!(Instant::now() < deadline, "Command did not exit");
            thread::sleep(Duration::from_millis(5));
        }
        self.drain();
        assert!(self.output.windows(8).any(|bytes| bytes == b"\x1b[?1049l"));
        let mut restored: libc::termios = unsafe { std::mem::zeroed() };
        assert_eq!(
            unsafe { libc::tcgetattr(self.slave.as_raw_fd(), &mut restored) },
            0,
            "{}",
            io::Error::last_os_error()
        );
        assert_eq!(restored.c_iflag, self.original.c_iflag);
        assert_eq!(restored.c_oflag, self.original.c_oflag);
        assert_eq!(restored.c_cflag, self.original.c_cflag);
        // PENDIN describes kernel input state, which can change when canonical mode is restored.
        let local_flags = !libc::PENDIN;
        assert_eq!(
            restored.c_lflag & local_flags,
            self.original.c_lflag & local_flags
        );
        assert_eq!(restored.c_cc, self.original.c_cc);
    }
}

impl Drop for Pty {
    fn drop(&mut self) {
        if self.child.try_wait().ok().flatten().is_none() {
            let _ = self.child.kill();
            let _ = self.child.wait();
        }
    }
}

#[test]
fn commands_restore_terminal_and_handle_wakeups() {
    let dir = tempfile::tempdir().unwrap();
    std::fs::write(dir.path().join("file"), b"hello").unwrap();
    let mut disk = Command::new(env!("CARGO_BIN_EXE_diskmap"));
    disk.arg(dir.path()).env("SSH_CONNECTION", "terminal-test");
    let mut disk = Pty::start(disk);
    disk.wait_for(b"diskmap");
    disk.wait_for(b"READY");
    disk.keys(b"y");
    disk.wait_for(b"\x1b]52;c;");
    disk.keys(b"?");
    disk.wait_for(b"Help");
    disk.keys(b"q");
    disk.finish(true);

    let mut memory = Command::new(env!("CARGO_BIN_EXE_memmap"));
    memory.args(["--view", "system", "--interval", "0.1"]);
    let mut memory = Pty::start(memory);
    memory.wait_for(b"LIVE");
    memory.keys(b" ");
    memory.wait_for(b"PAUSED");
    thread::sleep(Duration::from_millis(100));
    memory.drain();
    let paused_bytes = memory.output.len();
    thread::sleep(Duration::from_millis(2200));
    memory.drain();
    assert_eq!(
        memory.output.len(),
        paused_bytes,
        "Paused view redrew while idle"
    );
    memory.keys(b"r");
    memory.wait_for(b"fresh sample");
    memory.keys(b" q");
    memory.finish(true);
}

#[test]
fn ctrl_o_from_launch_directory_discovers_parent_entries() {
    let dir = tempfile::tempdir().unwrap();
    let launch = dir.path().join("launch");
    std::fs::create_dir(&launch).unwrap();
    std::fs::write(launch.join("file"), b"hello").unwrap();
    std::fs::write(dir.path().join("parent-only-file"), b"parent").unwrap();
    let mut disk = Command::new(env!("CARGO_BIN_EXE_diskmap"));
    disk.current_dir(&launch);
    let mut disk = Pty::start(disk);
    disk.wait_for(b"READY");
    disk.output.clear();
    disk.keys(b"\x0f");
    disk.wait_for(b"parent-only-file");
    disk.wait_for(b"READY");
    disk.keys(b"q");
    disk.finish(true);
}

#[test]
fn terminal_restores_after_normal_exit_error_and_panic() {
    for mode in ["ok", "error", "panic"] {
        let mut probe = Command::new(std::env::current_exe().unwrap());
        probe
            .args([
                "--exact",
                "terminal_lifecycle_probe",
                "--nocapture",
                "--test-threads=1",
            ])
            .env("USAGE_TUI_PROBE", mode);
        let mut probe = Pty::start(probe);
        probe.finish(mode != "panic");
    }
}

#[test]
fn terminal_lifecycle_probe() {
    let Ok(mode) = std::env::var("USAGE_TUI_PROBE") else {
        return;
    };
    let result = usage_tui::terminal::with_terminal(|terminal| {
        terminal.draw(|frame| {
            frame.render_widget(ratatui::widgets::Paragraph::new("probe"), frame.area())
        })?;
        match mode.as_str() {
            "panic" => panic!("terminal panic probe"),
            "error" => anyhow::bail!("terminal error probe"),
            _ => Ok(()),
        }
    });
    assert_eq!(result.is_err(), mode == "error");
}
