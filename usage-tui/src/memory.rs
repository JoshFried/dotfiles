use std::{
    collections::BTreeMap,
    path::{Path, PathBuf},
    sync::mpsc::{self, Receiver, Sender},
    thread,
    time::{Duration, Instant},
};

use crate::events::Wake;
use anyhow::{Context, Result, bail};
use sysinfo::{MemoryRefreshKind, ProcessRefreshKind, ProcessesToUpdate, System, UpdateKind};

#[derive(Clone, Debug)]
pub struct Process {
    pub pid: u32,
    pub started: u64,
    pub name: String,
    pub executable: Option<PathBuf>,
    pub command: Option<String>,
    pub resident: u64,
}

impl Process {
    pub fn id(&self) -> String {
        format!("pid:{}:{}", self.pid, self.started)
    }

    pub fn details(&self) -> String {
        format!(
            "PID {} · start {} · reported resident memory {}\nExecutable: {}\nCommand: {}{}",
            self.pid,
            self.started,
            crate::bytes(self.resident),
            self.executable
                .as_ref()
                .map(|p| p.to_string_lossy().into_owned())
                .unwrap_or_else(|| "unavailable".into()),
            self.command.as_deref().unwrap_or("unavailable"),
            if self.resident == 0 {
                "\nResident memory: zero reported; may be unavailable"
            } else {
                ""
            },
        )
    }
}

#[derive(Clone, Debug)]
pub struct App {
    pub id: String,
    pub name: String,
    pub resident: u64,
    pub processes: Vec<Process>,
}

pub fn group_identity(executable: Option<&Path>, name: &str, macos: bool) -> String {
    if let Some(path) = executable {
        if macos {
            let mut bundle = PathBuf::new();
            for component in path.components() {
                bundle.push(component);
                if bundle.extension().is_some_and(|ext| ext == "app") {
                    return bundle.to_string_lossy().into_owned();
                }
            }
        }
        if !path.as_os_str().is_empty() {
            return path.to_string_lossy().into_owned();
        }
    }
    format!("name:{name}")
}

pub fn group_processes(processes: Vec<Process>, macos: bool) -> Vec<App> {
    let mut apps = BTreeMap::<String, App>::new();
    for process in processes {
        let id = group_identity(process.executable.as_deref(), &process.name, macos);
        let name = if id.starts_with("name:") {
            process.name.clone()
        } else {
            Path::new(&id)
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .into_owned()
        };
        let app = apps.entry(id.clone()).or_insert_with(|| App {
            id,
            name,
            resident: 0,
            processes: Vec::new(),
        });
        app.resident = app.resident.saturating_add(process.resident);
        app.processes.push(process);
    }
    let mut apps: Vec<_> = apps.into_values().collect();
    apps.sort_by(|a, b| b.resident.cmp(&a.resident).then_with(|| a.id.cmp(&b.id)));
    for app in &mut apps {
        app.processes
            .sort_by(|a, b| b.resident.cmp(&a.resident).then_with(|| a.pid.cmp(&b.pid)));
    }
    apps
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Category {
    pub name: String,
    pub bytes: u64,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Breakdown {
    pub total: u64,
    pub categories: Vec<Category>,
    pub overlaps: String,
}

pub fn account(total: u64, categories: &[(&str, u64)], overlaps: String) -> Result<Breakdown> {
    if total == 0 {
        bail!("Physical memory total is unavailable");
    }
    let used = categories
        .iter()
        .try_fold(0u64, |sum, (_, bytes)| sum.checked_add(*bytes))
        .context("System category total overflowed")?;
    if used > total {
        bail!("Inconsistent system sample: categories exceed physical RAM");
    }
    let mut categories: Vec<_> = categories
        .iter()
        .map(|(name, bytes)| Category {
            name: (*name).into(),
            bytes: *bytes,
        })
        .collect();
    categories.push(Category {
        name: "Other".into(),
        bytes: total - used,
    });
    Ok(Breakdown {
        total,
        categories,
        overlaps,
    })
}

pub fn linux_breakdown(text: &str) -> Result<Breakdown> {
    let mut values = BTreeMap::new();
    for line in text.lines() {
        if let Some((key, raw)) = line.split_once(':') {
            let mut fields = raw.split_whitespace();
            let value: u64 = fields
                .next()
                .context("Missing /proc/meminfo value")?
                .parse()?;
            if fields.next() == Some("kB") {
                values.insert(
                    key,
                    value.checked_mul(1024).context("Memory value overflowed")?,
                );
            }
        }
    }
    let get = |key| {
        values
            .get(key)
            .copied()
            .with_context(|| format!("Missing /proc/meminfo {key}"))
    };
    let kernel = get("Slab")?
        .checked_add(get("KernelStack")?)
        .and_then(|n| n.checked_add(values.get("PageTables").copied()?))
        .context("Missing or overflowing kernel memory")?;
    account(
        get("MemTotal")?,
        &[
            ("Free", get("MemFree")?),
            ("Active", get("Active")?),
            ("Inactive", get("Inactive")?),
            ("Kernel", kernel),
        ],
        format!(
            "Overlapping cache (not extra tiles): Cached {} · Buffers {} · available {}",
            crate::bytes(get("Cached")?),
            crate::bytes(get("Buffers")?),
            crate::bytes(get("MemAvailable")?)
        ),
    )
}

#[cfg(target_os = "linux")]
fn native_breakdown(_: u64) -> Result<Breakdown> {
    linux_breakdown(&std::fs::read_to_string("/proc/meminfo")?)
}

#[cfg(target_os = "macos")]
#[allow(deprecated)]
fn native_breakdown(total: u64) -> Result<Breakdown> {
    unsafe extern "C" {
        fn mach_port_deallocate(
            task: libc::mach_port_t,
            name: libc::mach_port_t,
        ) -> libc::kern_return_t;
    }
    unsafe {
        let page_size = libc::sysconf(libc::_SC_PAGESIZE);
        if page_size <= 0 {
            bail!("Cannot obtain Mach page size");
        }
        let host = libc::mach_host_self();
        let mut stats: libc::vm_statistics64 = std::mem::zeroed();
        let mut count = libc::HOST_VM_INFO64_COUNT;
        let result = libc::host_statistics64(
            host,
            libc::HOST_VM_INFO64,
            (&mut stats as *mut libc::vm_statistics64).cast(),
            &mut count,
        );
        mach_port_deallocate(libc::mach_task_self(), host);
        if result != libc::KERN_SUCCESS {
            bail!("Mach VM statistics unavailable: {result}");
        }
        let pages = |n: u32| u64::from(n) * page_size as u64;
        account(
            total,
            &[
                ("Free", pages(stats.free_count)),
                ("Active", pages(stats.active_count)),
                ("Inactive", pages(stats.inactive_count)),
                ("Wired", pages(stats.wire_count)),
                ("Compressed", pages(stats.compressor_page_count)),
            ],
            format!(
                "Overlapping pages (not extra tiles): speculative {} · purgeable {} · file-backed {}",
                crate::bytes(pages(stats.speculative_count)),
                crate::bytes(pages(stats.purgeable_count)),
                crate::bytes(pages(stats.external_page_count)),
            ),
        )
    }
}

#[derive(Clone, Debug)]
pub struct Snapshot {
    pub apps: Vec<App>,
    pub ram: u64,
    pub available: u64,
    pub swap_used: u64,
    pub swap_total: u64,
    pub breakdown: Option<Breakdown>,
    pub warning: Option<String>,
    pub taken: Instant,
    pub requested: bool,
}

pub struct Collector {
    system: System,
    last_valid: Option<Breakdown>,
}

impl Default for Collector {
    fn default() -> Self {
        Self {
            system: System::new(),
            last_valid: None,
        }
    }
}

impl Collector {
    pub fn sample(&mut self) -> Snapshot {
        self.system
            .refresh_memory_specifics(MemoryRefreshKind::nothing().with_ram().with_swap());
        self.system.refresh_processes_specifics(
            ProcessesToUpdate::All,
            true,
            ProcessRefreshKind::nothing()
                .without_tasks()
                .with_memory()
                .with_exe(UpdateKind::Always)
                .with_cmd(UpdateKind::Always),
        );
        let processes = self
            .system
            .processes()
            .values()
            .map(|process| Process {
                pid: process.pid().as_u32(),
                started: process.start_time(),
                name: process.name().to_string_lossy().into_owned(),
                executable: process
                    .exe()
                    .filter(|p| !p.as_os_str().is_empty())
                    .map(Path::to_owned),
                command: (!process.cmd().is_empty()).then(|| {
                    process
                        .cmd()
                        .iter()
                        .map(|s| s.to_string_lossy())
                        .collect::<Vec<_>>()
                        .join(" ")
                }),
                resident: process.memory(),
            })
            .collect();
        let warning = self.update_breakdown(native_breakdown(self.system.total_memory()));
        Snapshot {
            apps: group_processes(processes, cfg!(target_os = "macos")),
            ram: self.system.total_memory(),
            available: self.system.available_memory(),
            swap_used: self.system.used_swap(),
            swap_total: self.system.total_swap(),
            breakdown: self.last_valid.clone(),
            warning,
            taken: Instant::now(),
            requested: false,
        }
    }

    fn update_breakdown(&mut self, result: Result<Breakdown>) -> Option<String> {
        match result {
            Ok(breakdown) => {
                self.last_valid = Some(breakdown);
                None
            }
            Err(error) => Some(format!("{error:#}; retaining last valid system breakdown")),
        }
    }
}

pub enum Command {
    Pause(bool),
    Refresh,
    Stop,
}

pub struct Sampler {
    pub snapshots: Receiver<Snapshot>,
    pub commands: Sender<Command>,
    pub wake: Wake,
}

impl Sampler {
    pub fn start(interval: Duration) -> Self {
        let mut collector = Collector::default();
        Self::spawn(interval, move || collector.sample())
    }

    fn spawn(interval: Duration, mut collect: impl FnMut() -> Snapshot + Send + 'static) -> Self {
        let (sender, snapshots) = mpsc::sync_channel(1);
        let (commands, receiver) = mpsc::channel();
        let wake = Wake::default();
        let worker_wake = wake.clone();
        thread::spawn(move || {
            let mut paused = false;
            let mut next = Instant::now();
            loop {
                let command = if paused {
                    receiver
                        .recv()
                        .map_err(|_| mpsc::RecvTimeoutError::Disconnected)
                } else {
                    receiver.recv_timeout(next.saturating_duration_since(Instant::now()))
                };
                let (sample, requested) = match command {
                    Ok(Command::Stop) | Err(mpsc::RecvTimeoutError::Disconnected) => break,
                    Ok(Command::Pause(value)) => {
                        paused = value;
                        if !paused {
                            next = Instant::now();
                        }
                        (false, false)
                    }
                    Ok(Command::Refresh) => (true, true),
                    Err(mpsc::RecvTimeoutError::Timeout) => (true, false),
                };
                if sample {
                    let mut snapshot = collect();
                    snapshot.requested = requested;
                    if requested {
                        if sender.send(snapshot).is_err() {
                            break;
                        }
                    } else if let Err(mpsc::TrySendError::Disconnected(_)) =
                        sender.try_send(snapshot)
                    {
                        break;
                    }
                    worker_wake.notify();
                    next = Instant::now() + interval;
                }
            }
        });
        Self {
            snapshots,
            commands,
            wake,
        }
    }
}

impl Drop for Sampler {
    fn drop(&mut self) {
        let _ = self.commands.send(Command::Stop);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn process(pid: u32, started: u64, executable: Option<&str>) -> Process {
        Process {
            pid,
            started,
            name: "test".into(),
            executable: executable.map(PathBuf::from),
            command: None,
            resident: 100,
        }
    }

    #[test]
    fn groups_outermost_bundle_or_executable_or_name() {
        let path = Path::new(
            "/Applications/Browser.app/Contents/Helpers/Helper.app/Contents/MacOS/helper",
        );
        assert_eq!(
            group_identity(Some(path), "helper", true),
            "/Applications/Browser.app"
        );
        assert_eq!(
            group_identity(Some(path), "helper", false),
            path.to_str().unwrap()
        );
        assert_eq!(group_identity(None, "helper", true), "name:helper");
        let apps = group_processes(
            vec![
                process(1, 1, Some("/usr/bin/test")),
                process(2, 2, Some("/usr/bin/test")),
            ],
            false,
        );
        assert_eq!(apps.len(), 1);
        assert_eq!(apps[0].resident, 200);
    }

    #[test]
    fn pid_reuse_and_process_exit_have_distinct_identities() {
        assert_ne!(process(1, 1, None).id(), process(1, 2, None).id());
        let apps = group_processes(vec![process(2, 1, None)], false);
        assert_eq!(apps[0].processes.len(), 1);
        assert_eq!(apps[0].processes[0].pid, 2);
        assert!(process(1, 1, None).details().contains("unavailable"));
        assert!(process(1, 1, None).details().contains("reported resident"));
    }

    #[test]
    fn accounting_excludes_overlapping_cache_and_rejects_inconsistency() {
        let text = "MemTotal: 1000 kB\nMemFree: 100 kB\nActive: 200 kB\nInactive: 300 kB\nSlab: 50 kB\nKernelStack: 10 kB\nPageTables: 10 kB\nCached: 500 kB\nBuffers: 50 kB\nMemAvailable: 500 kB";
        let breakdown = linux_breakdown(text).unwrap();
        assert_eq!(
            breakdown.categories.iter().map(|c| c.bytes).sum::<u64>(),
            breakdown.total
        );
        assert_eq!(breakdown.categories.last().unwrap().bytes, 330 * 1024);
        assert!(account(100, &[("Free", 101)], String::new()).is_err());
        assert!(linux_breakdown("MemTotal: 1000 kB").is_err());
        let mac = account(
            100,
            &[
                ("Free", 10),
                ("Active", 20),
                ("Inactive", 30),
                ("Wired", 15),
                ("Compressed", 5),
            ],
            "speculative 5 (already free)".into(),
        )
        .unwrap();
        assert_eq!(mac.categories.last().unwrap().bytes, 20);
    }

    #[test]
    fn native_collector_smoke() {
        let snapshot = Collector::default().sample();
        assert!(snapshot.ram > 0);
        assert!(!snapshot.apps.is_empty());
        let breakdown = snapshot.breakdown.expect("Native system breakdown");
        assert_eq!(
            breakdown.categories.iter().map(|c| c.bytes).sum::<u64>(),
            breakdown.total
        );
        assert!(snapshot.swap_used <= snapshot.swap_total);
    }

    #[test]
    fn invalid_sample_retains_last_valid_breakdown() {
        let mut collector = Collector::default();
        let valid = account(100, &[("Free", 20)], String::new()).unwrap();
        assert!(collector.update_breakdown(Ok(valid.clone())).is_none());
        let warning = collector.update_breakdown(account(100, &[("Free", 101)], String::new()));
        assert!(warning.unwrap().contains("retaining last valid"));
        assert_eq!(collector.last_valid, Some(valid));
    }

    #[test]
    fn worker_pauses_refreshes_once_and_resumes() {
        let sampler = Sampler::spawn(Duration::from_millis(20), || Snapshot {
            apps: Vec::new(),
            ram: 100,
            available: 20,
            swap_used: 0,
            swap_total: 0,
            breakdown: None,
            warning: None,
            taken: Instant::now(),
            requested: false,
        });
        sampler
            .snapshots
            .recv_timeout(Duration::from_secs(2))
            .unwrap();
        sampler.commands.send(Command::Pause(true)).unwrap();
        sampler.commands.send(Command::Refresh).unwrap();
        loop {
            let sample = sampler
                .snapshots
                .recv_timeout(Duration::from_secs(2))
                .unwrap();
            if sample.requested {
                break;
            }
        }
        assert!(matches!(
            sampler.snapshots.recv_timeout(Duration::from_millis(80)),
            Err(mpsc::RecvTimeoutError::Timeout)
        ));
        sampler.commands.send(Command::Pause(false)).unwrap();
        assert!(
            !sampler
                .snapshots
                .recv_timeout(Duration::from_secs(2))
                .unwrap()
                .requested
        );
    }
}
