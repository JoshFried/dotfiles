use std::{
    collections::{BTreeSet, HashMap, HashSet},
    fs,
    os::unix::{ffi::OsStringExt, fs::MetadataExt},
    path::{Path, PathBuf},
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
        mpsc::{self, Receiver, SyncSender},
    },
    thread,
    time::{Duration, Instant},
};

use crate::events::Wake;
use anyhow::{Context, Result, bail};
use walkdir::WalkDir;

pub fn path_id(path: &Path) -> String {
    let mut id = String::from("disk:");
    for byte in path.as_os_str().as_encoded_bytes() {
        use std::fmt::Write;
        write!(&mut id, "{byte:02x}").unwrap();
    }
    id
}

pub fn path_from_id(id: &str) -> Option<PathBuf> {
    let encoded = id.strip_prefix("disk:")?;
    if !encoded.len().is_multiple_of(2) || !encoded.is_ascii() {
        return None;
    }
    let bytes = (0..encoded.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&encoded[i..i + 2], 16))
        .collect::<std::result::Result<Vec<_>, _>>()
        .ok()?;
    Some(PathBuf::from(std::ffi::OsString::from_vec(bytes)))
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Identity {
    device: u64,
    inode: u64,
    mode: u32,
    changed: (i64, i64),
}

impl Identity {
    fn from_metadata(metadata: &fs::Metadata) -> Self {
        Self {
            device: metadata.dev(),
            inode: metadata.ino(),
            mode: metadata.mode(),
            changed: (metadata.ctime(), metadata.ctime_nsec()),
        }
    }
}

#[derive(Clone, Debug)]
pub struct Node {
    pub path: PathBuf,
    pub name: String,
    pub directory: bool,
    pub symlink: bool,
    pub allocated: u64,
    pub apparent: u64,
    pub children: Vec<usize>,
    pub notes: Vec<String>,
    pub identity: Option<Identity>,
    pub incomplete: bool,
    parent: Option<usize>,
}

impl Node {
    pub fn size(&self, apparent: bool) -> u64 {
        if apparent {
            self.apparent
        } else {
            self.allocated
        }
    }
}

#[derive(Clone, Debug)]
pub struct Tree {
    pub nodes: Vec<Node>,
    pub paths: HashMap<PathBuf, usize>,
    pub warnings: usize,
}

impl Tree {
    fn add(&mut self, path: PathBuf, metadata: Option<&fs::Metadata>) -> usize {
        if let Some(index) = self.paths.get(&path) {
            return *index;
        }
        let parent = path.parent().and_then(|p| self.paths.get(p)).copied();
        let index = self.nodes.len();
        self.nodes.push(Node {
            name: path
                .file_name()
                .unwrap_or(path.as_os_str())
                .to_string_lossy()
                .into_owned(),
            path: path.clone(),
            directory: metadata.is_some_and(|m| m.is_dir()),
            symlink: metadata.is_some_and(|m| m.file_type().is_symlink()),
            allocated: 0,
            apparent: 0,
            children: Vec::new(),
            notes: Vec::new(),
            identity: metadata.map(Identity::from_metadata),
            incomplete: false,
            parent,
        });
        self.paths.insert(path, index);
        if let Some(parent) = parent {
            self.nodes[parent].children.push(index);
        }
        index
    }

    pub fn sorted_children(&self, index: usize, apparent: bool) -> Vec<usize> {
        let mut children = self.nodes[index].children.clone();
        children.sort_by(|a, b| {
            self.nodes[*b]
                .size(apparent)
                .cmp(&self.nodes[*a].size(apparent))
                .then_with(|| self.nodes[*a].path.cmp(&self.nodes[*b].path))
        });
        children
    }

    fn attribute(
        &mut self,
        index: usize,
        allocated: u64,
        apparent: u64,
        dirty: &mut BTreeSet<usize>,
    ) {
        let mut current = Some(index);
        while let Some(index) = current {
            let node = &mut self.nodes[index];
            node.allocated = node.allocated.saturating_add(allocated);
            node.apparent = node.apparent.saturating_add(apparent);
            dirty.insert(index);
            current = node.parent;
        }
    }

    fn mark_incomplete(&mut self, index: usize, note: String, dirty: &mut BTreeSet<usize>) {
        self.nodes[index].notes.push(note);
        let mut current = Some(index);
        while let Some(at) = current {
            let node = &mut self.nodes[at];
            if at != index && !node.incomplete {
                node.notes
                    .push("Contains skipped or unreadable entries; totals are incomplete".into());
            }
            node.incomplete = true;
            dirty.insert(at);
            current = node.parent;
        }
        self.warnings += 1;
    }

    pub fn apply(&mut self, delta: ScanDelta) {
        for mut node in delta.nodes {
            let index = self.nodes.len();
            node.children.clear();
            if let Some(parent) = node.parent {
                self.nodes[parent].children.push(index);
            }
            self.paths.insert(node.path.clone(), index);
            self.nodes.push(node);
        }
        for update in delta.updates {
            let node = &mut self.nodes[update.index];
            node.allocated = update.allocated;
            node.apparent = update.apparent;
            node.incomplete = update.incomplete;
            node.notes = update.notes;
        }
        self.warnings = delta.warnings;
    }

    fn delta(&self, published: usize, dirty: &BTreeSet<usize>) -> ScanDelta {
        ScanDelta {
            nodes: self.nodes[published..]
                .iter()
                .map(|node| {
                    let mut node = node.clone();
                    node.children.clear();
                    node
                })
                .collect(),
            updates: dirty
                .iter()
                .filter(|index| **index < published)
                .map(|index| {
                    let node = &self.nodes[*index];
                    NodeUpdate {
                        index: *index,
                        allocated: node.allocated,
                        apparent: node.apparent,
                        incomplete: node.incomplete,
                        notes: node.notes.clone(),
                    }
                })
                .collect(),
            warnings: self.warnings,
        }
    }
}

pub struct NodeUpdate {
    index: usize,
    allocated: u64,
    apparent: u64,
    incomplete: bool,
    notes: Vec<String>,
}

pub struct ScanDelta {
    pub nodes: Vec<Node>,
    updates: Vec<NodeUpdate>,
    warnings: usize,
}

pub enum ScanEvent {
    Progress {
        entries: usize,
        path: PathBuf,
        delta: ScanDelta,
    },
    Complete(Tree),
    Failed(String),
}

pub struct Scanner {
    pub events: Receiver<ScanEvent>,
    cancel: Arc<AtomicBool>,
    pub wake: Wake,
}

impl Scanner {
    pub fn start(root: PathBuf) -> Self {
        Self::start_notified(root, Wake::default())
    }

    pub fn start_notified(root: PathBuf, wake: Wake) -> Self {
        let (sender, events) = mpsc::sync_channel(2);
        let cancel = Arc::new(AtomicBool::new(false));
        let worker_cancel = cancel.clone();
        let worker_wake = wake.clone();
        thread::spawn(move || {
            let mut published = 0;
            let result = scan_stream(
                &root,
                &worker_cancel,
                Duration::from_millis(150),
                |tree, dirty, path| {
                    let delta = tree.delta(published, dirty);
                    if sender
                        .try_send(ScanEvent::Progress {
                            entries: tree.nodes.len(),
                            path: path.to_owned(),
                            delta,
                        })
                        .is_ok()
                    {
                        published = tree.nodes.len();
                        worker_wake.notify();
                        true
                    } else {
                        false
                    }
                },
            );
            if !worker_cancel.load(Ordering::Relaxed) {
                let event = match result {
                    Ok(Some(tree)) => ScanEvent::Complete(tree),
                    Ok(None) => return,
                    Err(error) => ScanEvent::Failed(format!("{error:#}")),
                };
                send_final(&sender, &worker_cancel, &worker_wake, event);
            }
        });
        Self {
            events,
            cancel,
            wake,
        }
    }
}

fn send_final(sender: &SyncSender<ScanEvent>, cancel: &AtomicBool, wake: &Wake, event: ScanEvent) {
    if !cancel.load(Ordering::Relaxed) && sender.send(event).is_ok() {
        wake.notify();
    }
}

impl Drop for Scanner {
    fn drop(&mut self) {
        self.cancel.store(true, Ordering::Relaxed);
    }
}

pub fn scan(
    root: &Path,
    cancel: &AtomicBool,
    mut progress: impl FnMut(usize, &Path),
) -> Result<Option<Tree>> {
    scan_stream(root, cancel, Duration::from_millis(150), |tree, _, path| {
        progress(tree.nodes.len(), path);
        true
    })
}

fn scan_stream(
    root: &Path,
    cancel: &AtomicBool,
    interval: Duration,
    mut progress: impl FnMut(&Tree, &BTreeSet<usize>, &Path) -> bool,
) -> Result<Option<Tree>> {
    let root_metadata = fs::symlink_metadata(root).context("Cannot read scan root")?;
    let root_device = root_metadata.dev();
    let mut tree = Tree {
        nodes: Vec::new(),
        paths: HashMap::new(),
        warnings: 0,
    };
    tree.add(root.to_owned(), Some(&root_metadata));
    let mut owned = HashSet::new();
    let mut dirty = BTreeSet::new();
    let mut walker = WalkDir::new(root)
        .follow_links(false)
        .sort_by_file_name()
        .into_iter();
    let mut last_progress = Instant::now() - Duration::from_secs(1);
    while let Some(entry) = walker.next() {
        if cancel.load(Ordering::Relaxed) {
            return Ok(None);
        }
        let entry = match entry {
            Ok(entry) => entry,
            Err(error) => {
                let path = error.path().unwrap_or(root).to_owned();
                let metadata = fs::symlink_metadata(&path).ok();
                let index = tree.add(path, metadata.as_ref());
                tree.mark_incomplete(index, format!("Unreadable: {error}"), &mut dirty);
                continue;
            }
        };
        let metadata = match fs::symlink_metadata(entry.path()) {
            Ok(metadata) => metadata,
            Err(error) => {
                let index = tree.add(entry.path().to_owned(), None);
                tree.mark_incomplete(index, format!("Unavailable: {error}"), &mut dirty);
                if entry.file_type().is_dir() {
                    walker.skip_current_dir();
                }
                continue;
            }
        };
        let index = tree.add(entry.path().to_owned(), Some(&metadata));
        if metadata.dev() != root_device {
            tree.mark_incomplete(
                index,
                "Skipped mount: different filesystem".into(),
                &mut dirty,
            );
            if metadata.is_dir() {
                walker.skip_current_dir();
            }
        } else if metadata.is_file() {
            if owned.insert((metadata.dev(), metadata.ino())) {
                tree.attribute(
                    index,
                    metadata.blocks().saturating_mul(512),
                    metadata.len(),
                    &mut dirty,
                );
            } else {
                tree.nodes[index]
                    .notes
                    .push("Hard link: data counted at the first sorted path".into());
            }
        } else if metadata.file_type().is_symlink() {
            tree.attribute(
                index,
                metadata.blocks().saturating_mul(512),
                metadata.len(),
                &mut dirty,
            );
            tree.nodes[index]
                .notes
                .push("Symlink: target not followed".into());
        } else if !metadata.is_dir() {
            tree.nodes[index]
                .notes
                .push("Special file: no data bytes counted".into());
        }
        if last_progress.elapsed() >= interval {
            if progress(&tree, &dirty, entry.path()) {
                dirty.clear();
            }
            last_progress = Instant::now();
        }
    }
    if cancel.load(Ordering::Relaxed) {
        return Ok(None);
    }
    Ok(Some(tree))
}

pub trait TrashAdapter {
    fn move_to_trash(&mut self, path: &Path) -> Result<()>;
}

pub struct NativeTrash;

impl TrashAdapter for NativeTrash {
    fn move_to_trash(&mut self, path: &Path) -> Result<()> {
        let context = trash::TrashContext::new();
        #[cfg(target_os = "macos")]
        let context = {
            use trash::macos::{DeleteMethod, TrashContextExtMacos};
            path.to_str()
                .context("Native macOS Trash cannot safely represent this non-UTF-8 path")?;
            let mut context = context;
            context.set_delete_method(DeleteMethod::NsFileManager);
            context
        };
        context.delete(path).context("Move to Trash failed")
    }
}

#[derive(Clone, Debug)]
pub struct TrashRequest {
    pub path: PathBuf,
    pub size: u64,
    root: PathBuf,
    identity: Identity,
    parent: PathBuf,
    submitted: bool,
}

impl TrashRequest {
    pub fn prepare(root: &Path, node: &Node, apparent: bool) -> Result<Self> {
        if node.path == root || !node.path.starts_with(root) {
            bail!("The scanned root is protected");
        }
        let canonical_root = root.canonicalize()?;
        let parent = node
            .path
            .parent()
            .context("Missing parent")?
            .canonicalize()?;
        if !parent.starts_with(&canonical_root) {
            bail!("Path has moved outside the scanned root");
        }
        let identity = node
            .identity
            .clone()
            .context("Unavailable entries cannot be moved to Trash")?;
        if Identity::from_metadata(&fs::symlink_metadata(&node.path)?) != identity {
            bail!("Entry changed since scanning; refresh before moving it to Trash");
        }
        Ok(Self {
            path: parent.join(node.path.file_name().context("Missing entry name")?),
            size: node.size(apparent),
            root: canonical_root,
            identity,
            parent,
            submitted: false,
        })
    }

    pub fn execute(&mut self, confirmed: bool, adapter: &mut impl TrashAdapter) -> Result<()> {
        if !confirmed {
            bail!("Move to Trash was not confirmed");
        }
        if self.submitted {
            bail!("This request has already been submitted");
        }
        self.submitted = true;
        if self.path == self.root || !self.path.starts_with(&self.root) {
            bail!("The scanned root is protected");
        }
        let parent = self
            .path
            .parent()
            .context("Missing parent")?
            .canonicalize()?;
        if parent != self.parent || !parent.starts_with(&self.root) {
            bail!("Entry's parent changed; refresh before moving it to Trash");
        }
        let identity = Identity::from_metadata(&fs::symlink_metadata(&self.path)?);
        if identity != self.identity {
            bail!("Entry changed; refresh before moving it to Trash");
        }
        adapter.move_to_trash(&self.path)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::{PermissionsExt, symlink};

    fn fixture() -> tempfile::TempDir {
        tempfile::tempdir().unwrap()
    }

    #[test]
    fn path_identities_preserve_non_utf8_names() {
        let binary = PathBuf::from(std::ffi::OsString::from_vec(b"/demo/\xff".to_vec()));
        let unicode = PathBuf::from("/demo/�");
        assert_ne!(path_id(&binary), path_id(&unicode));
        assert_eq!(path_from_id(&path_id(&binary)), Some(binary));
        assert_eq!(path_from_id(&path_id(&unicode)), Some(unicode));
        assert!(path_from_id("disk:λ").is_none());
    }

    #[test]
    fn sparse_hidden_unicode_hardlinks_symlinks_and_special_files() {
        let dir = fixture();
        let root = dir.path();
        fs::create_dir(root.join("folder")).unwrap();
        fs::write(root.join(".hidden"), b"abc").unwrap();
        fs::write(root.join("λ"), b"unicode").unwrap();
        let sparse = fs::File::create(root.join("folder/sparse")).unwrap();
        sparse.set_len(8 * 1024 * 1024).unwrap();
        fs::hard_link(root.join(".hidden"), root.join("z-link")).unwrap();
        symlink(root.join("folder"), root.join("sym")).unwrap();
        let fifo_path =
            std::ffi::CString::new(root.join("fifo").as_os_str().as_encoded_bytes()).unwrap();
        assert_eq!(unsafe { libc::mkfifo(fifo_path.as_ptr(), 0o600) }, 0);
        let tree = scan(root, &AtomicBool::new(false), |_, _| {})
            .unwrap()
            .unwrap();
        assert!(tree.paths.contains_key(&root.join("λ")));
        assert!(tree.nodes[0].apparent >= 8 * 1024 * 1024 + 10);
        assert!(tree.nodes[0].allocated < tree.nodes[0].apparent);
        let hardlink = &tree.nodes[tree.paths[&root.join("z-link")]];
        assert_eq!(hardlink.apparent, 0);
        assert!(hardlink.notes[0].contains("Hard link"));
        let symlink = &tree.nodes[tree.paths[&root.join("sym")]];
        assert!(symlink.children.is_empty());
        assert!(symlink.symlink);
        assert!(!tree.nodes[0].incomplete);
        assert!(tree.nodes[0].notes.is_empty());
    }

    #[test]
    fn cancellation_discards_partial_tree() {
        let dir = fixture();
        fs::write(dir.path().join("file"), b"x").unwrap();
        let cancel = AtomicBool::new(false);
        let result = scan(dir.path(), &cancel, |_, _| {
            cancel.store(true, Ordering::Relaxed)
        })
        .unwrap();
        assert!(result.is_none());
    }

    #[test]
    fn unreadable_is_annotated_when_permissions_are_enforced() {
        let dir = fixture();
        let folder = dir.path().join("unreadable");
        fs::create_dir(&folder).unwrap();
        fs::write(folder.join("data"), b"data").unwrap();
        fs::set_permissions(&folder, fs::Permissions::from_mode(0o0)).unwrap();
        let tree = scan(dir.path(), &AtomicBool::new(false), |_, _| {})
            .unwrap()
            .unwrap();
        if unsafe { libc::geteuid() } != 0 {
            assert!(tree.warnings > 0);
            assert!(
                tree.nodes[tree.paths[&folder]]
                    .notes
                    .iter()
                    .any(|n| n.contains("Unreadable"))
            );
            assert!(tree.nodes[0].incomplete);
            assert!(
                tree.nodes[0]
                    .notes
                    .iter()
                    .any(|note| note.contains("incomplete"))
            );
        }
        fs::set_permissions(&folder, fs::Permissions::from_mode(0o700)).unwrap();
    }

    #[derive(Default)]
    struct MockTrash {
        calls: usize,
        fail: bool,
    }
    impl TrashAdapter for MockTrash {
        fn move_to_trash(&mut self, _: &Path) -> Result<()> {
            self.calls += 1;
            if self.fail {
                bail!("mock trash failure");
            }
            Ok(())
        }
    }

    #[test]
    fn trash_requires_confirmation_revalidates_and_prevents_duplicates() {
        let dir = fixture();
        fs::write(dir.path().join("file"), b"data").unwrap();
        let tree = scan(dir.path(), &AtomicBool::new(false), |_, _| {})
            .unwrap()
            .unwrap();
        assert!(TrashRequest::prepare(dir.path(), &tree.nodes[0], false).is_err());
        let mut request = TrashRequest::prepare(dir.path(), &tree.nodes[1], false).unwrap();
        let mut trash = MockTrash::default();
        assert!(request.execute(false, &mut trash).is_err());
        assert_eq!(trash.calls, 0);
        request.execute(true, &mut trash).unwrap();
        assert!(request.execute(true, &mut trash).is_err());
        assert_eq!(trash.calls, 1);
        let mut changed = TrashRequest::prepare(dir.path(), &tree.nodes[1], false).unwrap();
        fs::rename(dir.path().join("file"), dir.path().join("old")).unwrap();
        fs::write(dir.path().join("file"), b"new").unwrap();
        assert!(changed.execute(true, &mut trash).is_err());
        assert_eq!(trash.calls, 1);
    }

    #[test]
    fn trash_failure_does_not_delete_file() {
        let dir = fixture();
        fs::write(dir.path().join("file"), b"data").unwrap();
        let tree = scan(dir.path(), &AtomicBool::new(false), |_, _| {})
            .unwrap()
            .unwrap();
        let mut request = TrashRequest::prepare(dir.path(), &tree.nodes[1], false).unwrap();
        let mut trash = MockTrash {
            fail: true,
            ..Default::default()
        };
        assert!(request.execute(true, &mut trash).is_err());
        assert!(request.path.exists());
        assert_eq!(trash.calls, 1);
    }

    #[test]
    fn trash_rejects_replaced_parent() {
        let dir = fixture();
        let outside = fixture();
        fs::create_dir(dir.path().join("folder")).unwrap();
        fs::write(dir.path().join("folder/file"), b"data").unwrap();
        let tree = scan(dir.path(), &AtomicBool::new(false), |_, _| {})
            .unwrap()
            .unwrap();
        let node = &tree.nodes[tree.paths[&dir.path().join("folder/file")]];
        let mut request = TrashRequest::prepare(dir.path(), node, false).unwrap();
        fs::rename(dir.path().join("folder"), dir.path().join("old")).unwrap();
        symlink(outside.path(), dir.path().join("folder")).unwrap();
        let mut trash = MockTrash::default();
        assert!(request.execute(true, &mut trash).is_err());
        assert_eq!(trash.calls, 0);
        assert!(dir.path().join("old/file").exists());
    }

    #[test]
    fn worker_delivers_completed_tree_after_bounded_progress() {
        let dir = fixture();
        for index in 0..500 {
            fs::write(dir.path().join(format!("{index:04}")), b"x").unwrap();
        }
        let scanner = Scanner::start(dir.path().to_owned());
        let deadline = Instant::now() + Duration::from_secs(5);
        loop {
            match scanner
                .events
                .recv_timeout(deadline.saturating_duration_since(Instant::now()))
                .unwrap()
            {
                ScanEvent::Progress { .. } => {}
                ScanEvent::Complete(tree) => {
                    assert_eq!(tree.nodes.len(), 501);
                    break;
                }
                ScanEvent::Failed(error) => panic!("{error}"),
            }
        }
    }

    #[test]
    fn streamed_totals_are_browsable_and_coalesce_without_lost_nodes() {
        let dir = fixture();
        fs::create_dir(dir.path().join("folder")).unwrap();
        for index in 0..20 {
            fs::write(
                dir.path().join("folder").join(format!("{index:02}")),
                b"hello",
            )
            .unwrap();
        }
        let mut preview = Tree {
            nodes: Vec::new(),
            paths: HashMap::new(),
            warnings: 0,
        };
        let mut published = 0;
        let mut ticks = 0;
        let mut saw_partial_bytes = false;
        let complete = scan_stream(
            dir.path(),
            &AtomicBool::new(false),
            Duration::ZERO,
            |tree, dirty, _| {
                ticks += 1;
                if ticks % 3 == 0 && tree.nodes.len() < 22 {
                    return false;
                }
                preview.apply(tree.delta(published, dirty));
                published = tree.nodes.len();
                if published < 22 && preview.nodes[0].apparent > 0 {
                    saw_partial_bytes = true;
                }
                assert_eq!(preview.nodes[0].apparent, tree.nodes[0].apparent);
                true
            },
        )
        .unwrap()
        .unwrap();
        assert!(saw_partial_bytes);
        assert_eq!(preview.nodes.len(), complete.nodes.len());
        assert_eq!(preview.nodes[0].apparent, 100);
        assert_eq!(preview.nodes[0].apparent, complete.nodes[0].apparent);
        assert_eq!(preview.nodes[1].children, complete.nodes[1].children);
    }
}
