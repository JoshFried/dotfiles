use std::{
    collections::HashMap,
    io,
    path::PathBuf,
    sync::mpsc::{self, Receiver},
    thread,
    time::Duration,
};

use anyhow::{Context, Result, bail};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use ratatui::{
    Frame,
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span, Text},
    widgets::{
        Block, BorderType, Borders, Clear, List, ListItem, ListState, Paragraph, Sparkline, Wrap,
    },
};

use crate::{
    bytes,
    chrome::{self, Hint},
    disk::{NativeTrash, ScanEvent, Scanner, TrashRequest, Tree},
    events::{AppEvent, Wake},
    fuzzy_match,
    history::History,
    memory::{Command, Sampler, Snapshot},
    theme,
    treemap::{self, Direction, Item, Sizing, StableLayout, Tile},
};

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum View {
    Disk(PathBuf),
    Apps,
    System,
    Processes(String),
    Other { parent: Box<View>, ids: Vec<String> },
}

#[derive(Clone)]
struct Location {
    view: View,
    selected: Option<String>,
    query: String,
    list_focus: bool,
    list_offset: usize,
}

#[derive(Clone, Copy, Default, PartialEq, Eq)]
enum SortOrder {
    #[default]
    Size,
    Name,
}

pub struct DiskState {
    root: PathBuf,
    tree: Option<Tree>,
    preview: Option<Tree>,
    scanner: Option<Scanner>,
    apparent: bool,
    trash_job: Option<Receiver<Result<(), String>>>,
}

impl DiskState {
    fn tree_for(&self, path: &std::path::Path) -> Option<&Tree> {
        self.preview
            .as_ref()
            .filter(|tree| tree.paths.contains_key(path))
            .or(self.tree.as_ref())
    }
}

pub struct MemoryState {
    sampler: Sampler,
    snapshot: Option<Snapshot>,
    paused: bool,
    trends: History,
}

pub enum Mode {
    Disk(DiskState),
    Memory(MemoryState),
}

enum Dialog {
    Help {
        scroll: u16,
    },
    Details {
        title: String,
        body: String,
        scroll: u16,
    },
    Trash {
        request: TrashRequest,
        scroll: u16,
    },
}

pub struct AppState {
    pub mode: Mode,
    pub view: View,
    history: Vec<Location>,
    items: Vec<Item>,
    full_total: u64,
    selected: Option<String>,
    aggregate: Vec<String>,
    list_focus: bool,
    query: String,
    searching: bool,
    query_before: String,
    dialog: Option<Dialog>,
    status: String,
    status_color: Color,
    geometry: Vec<Tile>,
    list_state: ListState,
    quit: bool,
    sort: SortOrder,
    sizing: Sizing,
    pending_g: bool,
    list_page: usize,
    pending_copy: Option<String>,
    copying: bool,
    stable_layout: StableLayout,
    wake: Wake,
}

impl AppState {
    pub fn disk(root: PathBuf, apparent: bool) -> Result<Self> {
        let root = root.canonicalize().context("Cannot resolve diskmap path")?;
        let mode = Mode::Disk(DiskState {
            scanner: Some(Scanner::start(root.clone())),
            root: root.clone(),
            tree: None,
            preview: None,
            apparent,
            trash_job: None,
        });
        Ok(Self::new(mode, View::Disk(root), "Scanning…".into()))
    }

    pub fn memory(interval: Duration, system: bool) -> Self {
        Self::new(
            Mode::Memory(MemoryState {
                sampler: Sampler::start(interval),
                snapshot: None,
                paused: false,
                trends: History::default(),
            }),
            if system { View::System } else { View::Apps },
            "Sampling…".into(),
        )
    }

    fn new(mode: Mode, view: View, status: String) -> Self {
        let wake = match &mode {
            Mode::Disk(state) => state
                .scanner
                .as_ref()
                .map(|scanner| scanner.wake.clone())
                .unwrap_or_default(),
            Mode::Memory(state) => state.sampler.wake.clone(),
        };
        Self {
            mode,
            view,
            history: Vec::new(),
            items: Vec::new(),
            full_total: 0,
            selected: None,
            aggregate: Vec::new(),
            list_focus: false,
            query: String::new(),
            searching: false,
            query_before: String::new(),
            dialog: None,
            status,
            status_color: theme::BLUE,
            geometry: Vec::new(),
            list_state: ListState::default(),
            quit: false,
            sort: SortOrder::Size,
            sizing: Sizing::Balanced,
            pending_g: false,
            list_page: 10,
            pending_copy: None,
            copying: false,
            stable_layout: StableLayout::default(),
            wake,
        }
    }

    fn source_items(&self, view: &View) -> Vec<Item> {
        match (&self.mode, view) {
            (Mode::Disk(state), View::Disk(path)) => {
                let Some(tree) = state.tree_for(path) else {
                    return Vec::new();
                };
                let Some(index) = tree.paths.get(path) else {
                    return Vec::new();
                };
                let node = &tree.nodes[*index];
                let children = if node.directory {
                    tree.sorted_children(*index, state.apparent)
                } else {
                    vec![*index]
                };
                children
                    .into_iter()
                    .map(|index| {
                        let node = &tree.nodes[index];
                        Item {
                            id: crate::disk::path_id(&node.path),
                            name: format!("{}{}", node.name, if node.directory { "/" } else { "" }),
                            size: node.size(state.apparent),
                            detail: format!(
                                "{}\n{} · allocated {} · apparent {}{}",
                                node.path.display(),
                                if node.directory {
                                    "Folder"
                                } else if node.symlink {
                                    "Symlink"
                                } else {
                                    "File"
                                },
                                bytes(node.allocated),
                                bytes(node.apparent),
                                if node.notes.is_empty() {
                                    String::new()
                                } else {
                                    format!("\n{}", node.notes.join("; "))
                                }
                            ),
                        }
                    })
                    .collect()
            }
            (Mode::Memory(state), View::Apps) => state
                .snapshot
                .as_ref()
                .map(|s| {
                    s.apps
                        .iter()
                        .map(|app| Item {
                            id: app.id.clone(),
                            name: app.name.clone(),
                            size: app.resident,
                            detail: format!(
                                "{}\n{} processes · reported resident memory",
                                app.id,
                                app.processes.len()
                            ),
                        })
                        .collect()
                })
                .unwrap_or_default(),
            (Mode::Memory(state), View::Processes(id)) => state
                .snapshot
                .as_ref()
                .and_then(|s| s.apps.iter().find(|app| &app.id == id))
                .map(|app| {
                    app.processes
                        .iter()
                        .map(|process| Item {
                            id: process.id(),
                            name: format!("{} · PID {}", process.name, process.pid),
                            size: process.resident,
                            detail: process.details(),
                        })
                        .collect()
                })
                .unwrap_or_default(),
            (Mode::Memory(state), View::System) => state
                .snapshot
                .as_ref()
                .and_then(|s| s.breakdown.as_ref())
                .map(|breakdown| {
                    breakdown
                        .categories
                        .iter()
                        .map(|category| Item {
                            id: format!("system:{}", category.name),
                            name: category.name.clone(),
                            size: category.bytes,
                            detail: format!(
                                "Physical RAM category: {}\n{}",
                                category.name, breakdown.overlaps
                            ),
                        })
                        .collect()
                })
                .unwrap_or_default(),
            (_, View::Other { parent, ids }) => self
                .source_items(parent)
                .into_iter()
                .filter(|item| ids.contains(&item.id))
                .collect(),
            _ => Vec::new(),
        }
    }

    fn rebuild(&mut self, reorder: bool) {
        let mut items = self.source_items(&self.view);
        self.full_total = items.iter().map(|item| item.size).sum();
        items.retain(|item| fuzzy_match(&item.name, &self.query));
        if self.sort == SortOrder::Name {
            items.sort_by(|a, b| {
                a.name
                    .to_lowercase()
                    .cmp(&b.name.to_lowercase())
                    .then_with(|| a.id.cmp(&b.id))
            });
        } else if matches!(self.mode, Mode::Memory(_)) {
            if reorder {
                items.sort_by(|a, b| b.size.cmp(&a.size).then_with(|| a.id.cmp(&b.id)));
            } else {
                preserve_order(&mut items, &self.items);
            }
        }
        self.items = items;
        let selection_exists = self
            .items
            .iter()
            .any(|item| Some(&item.id) == self.selected.as_ref());
        let awaiting_scan = self.selected.is_some()
            && matches!(&self.mode, Mode::Disk(state) if state.scanner.is_some());
        if !selection_exists && !awaiting_scan {
            self.selected = self.items.first().map(|item| item.id.clone());
            self.aggregate.clear();
        }
        self.aggregate
            .retain(|id| self.items.iter().any(|item| &item.id == id));
        self.geometry.clear();
        if reorder {
            self.stable_layout.clear();
        }
    }

    pub fn update(&mut self) -> bool {
        let mut changed = false;
        let mut reload = false;
        let mut scan_complete = None;
        let mut trashed = None;
        let mut reorder = false;
        match &mut self.mode {
            Mode::Disk(state) => {
                if let Some(scanner) = &state.scanner {
                    while let Ok(event) = scanner.events.try_recv() {
                        changed = true;
                        match event {
                            ScanEvent::Progress {
                                entries,
                                path,
                                delta,
                            } => {
                                state
                                    .preview
                                    .get_or_insert_with(|| Tree {
                                        nodes: Vec::new(),
                                        paths: HashMap::new(),
                                        warnings: 0,
                                    })
                                    .apply(delta);
                                reload = true;
                                self.status = format!(
                                    "{entries} entries · provisional totals · {}",
                                    path.display()
                                );
                                self.status_color = theme::BLUE;
                            }
                            ScanEvent::Complete(tree) => {
                                self.status = format!(
                                    "{} entries · {} warnings",
                                    tree.nodes.len(),
                                    tree.warnings
                                );
                                scan_complete = Some(tree);
                                self.status_color = if scan_complete.as_ref().unwrap().warnings == 0
                                {
                                    theme::GREEN
                                } else {
                                    theme::SELECTED
                                };
                            }
                            ScanEvent::Failed(error) => {
                                self.status = error;
                                self.status_color = theme::RED;
                                scan_complete = Some(Tree {
                                    nodes: Vec::new(),
                                    paths: HashMap::new(),
                                    warnings: 0,
                                });
                            }
                        }
                    }
                }
                if let Some(tree) = scan_complete {
                    reload = true;
                    if !tree.nodes.is_empty() {
                        state.tree = Some(tree);
                    }
                    state.preview = None;
                    state.scanner = None;
                    if let Some(tree) = &state.tree {
                        repair_disk_view(&mut self.view, tree, &state.root);
                    }
                    reorder = true;
                }
                if let Some(job) = &state.trash_job
                    && let Ok(result) = job.try_recv()
                {
                    trashed = Some(result);
                }
            }
            Mode::Memory(state) => {
                while let Ok(snapshot) = state.sampler.snapshots.try_recv() {
                    if state.paused && !snapshot.requested {
                        continue;
                    }
                    self.status = snapshot.warning.clone().unwrap_or_else(|| {
                        if state.paused {
                            "Paused · fresh sample".into()
                        } else {
                            format!(
                                "{} apps · {} processes",
                                snapshot.apps.len(),
                                snapshot
                                    .apps
                                    .iter()
                                    .map(|app| app.processes.len())
                                    .sum::<usize>()
                            )
                        }
                    });
                    self.status_color = if snapshot.warning.is_some() {
                        theme::RED
                    } else if state.paused {
                        theme::SELECTED
                    } else {
                        theme::GREEN
                    };
                    reorder |= snapshot.requested || state.snapshot.is_none();
                    state.trends.record(&snapshot);
                    state.snapshot = Some(snapshot);
                    changed = true;
                    reload = true;
                }
            }
        }
        if let Some(result) = trashed {
            if let Mode::Disk(state) = &mut self.mode {
                state.trash_job = None;
            }
            match result {
                Ok(()) => {
                    self.rescan();
                    self.status = "Moved to Trash · space may remain used until Trash is emptied · rescanning…".into();
                }
                Err(error) => {
                    self.status = error;
                    self.status_color = theme::RED;
                }
            }
            changed = true;
        }
        if reload {
            self.rebuild(reorder);
        }
        changed
    }

    fn rescan(&mut self) {
        if let Mode::Disk(state) = &mut self.mode {
            state.scanner = None;
            state.preview = None;
            state.scanner = Some(Scanner::start_notified(
                state.root.clone(),
                self.wake.clone(),
            ));
            self.status = "Scanning root…".into();
            self.status_color = theme::BLUE;
        }
    }

    fn navigate(&mut self, view: View) {
        self.history.push(Location {
            view: self.view.clone(),
            selected: self.selected.clone(),
            query: self.query.clone(),
            list_focus: self.list_focus,
            list_offset: self.list_state.offset(),
        });
        self.view = view;
        self.query.clear();
        self.selected = None;
        self.aggregate.clear();
        self.list_state = ListState::default();
        if matches!(self.view, View::Other { .. }) {
            self.list_focus = true;
        }
        self.rebuild(true);
    }

    fn back(&mut self) {
        if let Some(location) = self.history.pop() {
            self.view = location.view;
            if let Mode::Disk(state) = &self.mode
                && let Some(tree) = &state.tree
            {
                repair_disk_view(&mut self.view, tree, &state.root);
            }
            self.selected = location.selected;
            self.query = location.query;
            self.list_focus = location.list_focus;
            self.aggregate.clear();
            self.list_state = ListState::default();
            *self.list_state.offset_mut() = location.list_offset;
            self.rebuild(true);
        } else if let View::Disk(path) = &self.view {
            let Some(parent) = path.parent().map(std::path::Path::to_path_buf) else {
                self.status = "Already at the filesystem root".into();
                self.status_color = theme::SELECTED;
                return;
            };
            let previous = path.clone();
            if let Mode::Disk(state) = &mut self.mode {
                let cached = state
                    .tree_for(&parent)
                    .is_some_and(|tree| tree.paths.contains_key(&parent));
                if !cached {
                    state.root = parent.clone();
                    self.rescan();
                }
            }
            self.view = View::Disk(parent);
            self.selected = Some(crate::disk::path_id(&previous));
            self.query.clear();
            self.aggregate.clear();
            self.list_state = ListState::default();
            self.rebuild(true);
        }
    }

    fn selected_index(&self) -> Option<usize> {
        self.items
            .iter()
            .position(|item| Some(&item.id) == self.selected.as_ref())
    }

    fn tile_index(&self) -> Option<usize> {
        let index = self.selected_index()?;
        self.geometry
            .iter()
            .position(|tile| tile.members.contains(&index))
    }

    fn select_tile(&mut self, index: usize) {
        if let Some(tile) = self.geometry.get(index) {
            self.selected = tile.members.first().map(|i| self.items[*i].id.clone());
            self.aggregate = if tile.members.len() > 1 {
                tile.members
                    .iter()
                    .map(|i| self.items[*i].id.clone())
                    .collect()
            } else {
                Vec::new()
            };
        }
    }

    fn move_selection(&mut self, direction: Direction) {
        if self.list_focus || self.geometry.is_empty() {
            if self.selected_index().is_none() {
                self.selected = self.items.first().map(|item| item.id.clone());
                self.aggregate.clear();
                return;
            }
            let index = self.selected_index().unwrap_or(0);
            let next = match direction {
                Direction::Down | Direction::Right => {
                    (index + 1).min(self.items.len().saturating_sub(1))
                }
                Direction::Up | Direction::Left => index.saturating_sub(1),
            };
            self.selected = self.items.get(next).map(|item| item.id.clone());
            self.aggregate.clear();
        } else if let Some(index) = self.tile_index() {
            if let Some(next) = treemap::neighbor(&self.geometry, index, direction) {
                self.select_tile(next);
            }
        } else if !self.geometry.is_empty() {
            self.select_tile(0);
        }
    }

    fn jump(&mut self, index: usize) {
        self.list_focus = true;
        self.aggregate.clear();
        self.selected = self
            .items
            .get(index.min(self.items.len().saturating_sub(1)))
            .map(|item| item.id.clone());
    }

    fn copy_path(&mut self) {
        if self.copying {
            self.status = "Clipboard copy in progress".into();
            return;
        }
        if !self.aggregate.is_empty() && !self.list_focus {
            self.status = "Select an individual entry to copy its path".into();
            return;
        }
        let Some(index) = self.selected_index() else {
            return;
        };
        let item = &self.items[index];
        let path = match &self.mode {
            Mode::Disk(_) => crate::disk::path_from_id(&item.id),
            Mode::Memory(state) => state.snapshot.as_ref().and_then(|snapshot| {
                snapshot.apps.iter().find_map(|app| {
                    if app.id == item.id && !app.id.starts_with("name:") {
                        Some(PathBuf::from(&app.id))
                    } else {
                        app.processes
                            .iter()
                            .find(|process| process.id() == item.id)
                            .and_then(|process| process.executable.clone())
                    }
                })
            }),
        };
        match path.and_then(|path| path.to_str().map(str::to_owned)) {
            Some(path) => {
                self.pending_copy = Some(path);
                self.copying = true;
                self.status = "Copying path to clipboard…".into();
                self.status_color = theme::BLUE;
            }
            None => {
                self.status = "No UTF-8 path is available for this entry".into();
                self.status_color = theme::SELECTED;
            }
        }
    }

    fn open(&mut self) {
        if !self.aggregate.is_empty() && !self.list_focus {
            self.navigate(View::Other {
                parent: Box::new(self.view.clone()),
                ids: self.aggregate.clone(),
            });
            return;
        }
        let Some(index) = self.selected_index() else {
            return;
        };
        let item = self.items[index].clone();
        match &self.mode {
            Mode::Disk(state) => {
                if let Some(path) = crate::disk::path_from_id(&item.id)
                    && let Some(tree) = state.tree_for(&path)
                    && let Some(node) = tree.paths.get(&path).map(|i| &tree.nodes[*i])
                    && node.directory
                {
                    self.navigate(View::Disk(node.path.clone()));
                    return;
                }
            }
            Mode::Memory(state) => {
                if state
                    .snapshot
                    .as_ref()
                    .is_some_and(|snapshot| snapshot.apps.iter().any(|app| app.id == item.id))
                {
                    self.navigate(View::Processes(item.id));
                    return;
                }
            }
        }
        self.dialog = Some(Dialog::Details {
            title: item.name,
            body: item.detail,
            scroll: 0,
        });
    }

    fn request_trash(&mut self) {
        if !self.aggregate.is_empty() && !self.list_focus {
            self.status = "Open Other and select a real entry before moving it to Trash".into();
            return;
        }
        let Mode::Disk(state) = &self.mode else {
            return;
        };
        if state.scanner.is_some() {
            self.status = "Wait for the scan to finish before moving entries to Trash".into();
            self.status_color = theme::SELECTED;
            return;
        }
        if state.trash_job.is_some() {
            self.status = "Move to Trash already in progress".into();
            return;
        }
        let Some(index) = self.selected_index() else {
            return;
        };
        let Some(tree) = &state.tree else {
            return;
        };
        let Some(path) = crate::disk::path_from_id(&self.items[index].id) else {
            return;
        };
        let Some(node) = tree.paths.get(&path).map(|i| &tree.nodes[*i]) else {
            return;
        };
        match TrashRequest::prepare(&state.root, node, state.apparent) {
            Ok(request) => self.dialog = Some(Dialog::Trash { request, scroll: 0 }),
            Err(error) => {
                self.status = format!("{error:#}");
                self.status_color = theme::RED;
            }
        }
    }

    pub fn key(&mut self, key: KeyEvent) {
        if key.kind != KeyEventKind::Press {
            return;
        }
        if key.code == KeyCode::Char('c') && key.modifiers.contains(KeyModifiers::CONTROL) {
            self.quit = true;
            return;
        }
        if !self.searching && key.code == KeyCode::Char('q') {
            self.quit = true;
            return;
        }
        if let Some(dialog) = &mut self.dialog {
            match key.code {
                KeyCode::Esc | KeyCode::Char('n') => self.dialog = None,
                KeyCode::Char('y') if matches!(dialog, Dialog::Trash { .. }) => {
                    if let Some(Dialog::Trash { mut request, .. }) = self.dialog.take()
                        && let Mode::Disk(state) = &mut self.mode
                        && state.trash_job.is_none()
                    {
                        let (sender, receiver) = mpsc::channel();
                        state.trash_job = Some(receiver);
                        self.status = "Moving to Trash…".into();
                        let wake = self.wake.clone();
                        thread::spawn(move || {
                            let result = request
                                .execute(true, &mut NativeTrash)
                                .map_err(|e| format!("{e:#}"));
                            let _ = sender.send(result);
                            wake.notify();
                        });
                    }
                }
                KeyCode::Char('j') | KeyCode::Down => match dialog {
                    Dialog::Help { scroll }
                    | Dialog::Details { scroll, .. }
                    | Dialog::Trash { scroll, .. } => *scroll = scroll.saturating_add(1),
                },
                KeyCode::Char('k') | KeyCode::Up => match dialog {
                    Dialog::Help { scroll }
                    | Dialog::Details { scroll, .. }
                    | Dialog::Trash { scroll, .. } => *scroll = scroll.saturating_sub(1),
                },
                _ => {}
            }
            return;
        }
        if self.searching {
            match key.code {
                KeyCode::Esc => {
                    self.query = self.query_before.clone();
                    self.searching = false;
                }
                KeyCode::Enter => self.searching = false,
                KeyCode::Backspace => {
                    self.query.pop();
                }
                KeyCode::Char(c) if !key.modifiers.contains(KeyModifiers::CONTROL) => {
                    self.query.push(c)
                }
                _ => return,
            }
            self.aggregate.clear();
            self.rebuild(true);
            return;
        }
        if self.pending_g {
            self.pending_g = false;
            if key.code == KeyCode::Char('g') {
                self.jump(0);
                return;
            }
        }
        match key.code {
            KeyCode::Char('q') => self.quit = true,
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => self.quit = true,
            KeyCode::Char('h') | KeyCode::Left => self.move_selection(Direction::Left),
            KeyCode::Char('j') | KeyCode::Down => self.move_selection(Direction::Down),
            KeyCode::Char('k') | KeyCode::Up => self.move_selection(Direction::Up),
            KeyCode::Char('l') | KeyCode::Right => self.move_selection(Direction::Right),
            KeyCode::Char('g') => self.pending_g = true,
            KeyCode::Char('G') | KeyCode::End => self.jump(self.items.len().saturating_sub(1)),
            KeyCode::Home => self.jump(0),
            KeyCode::PageDown => self.jump(
                self.selected_index()
                    .unwrap_or(0)
                    .saturating_add(self.list_page),
            ),
            KeyCode::PageUp => self.jump(
                self.selected_index()
                    .unwrap_or(0)
                    .saturating_sub(self.list_page),
            ),
            KeyCode::Char('s') => {
                self.sort = if self.sort == SortOrder::Size {
                    SortOrder::Name
                } else {
                    SortOrder::Size
                };
                self.rebuild(true);
            }
            KeyCode::Char('b') => {
                self.sizing = if self.sizing == Sizing::Balanced {
                    Sizing::Proportional
                } else {
                    Sizing::Balanced
                };
                self.aggregate.clear();
                self.geometry.clear();
                self.stable_layout.clear();
            }
            KeyCode::Char('y') => self.copy_path(),
            KeyCode::Enter => self.open(),
            KeyCode::Backspace => self.back(),
            KeyCode::Char('o') if key.modifiers.contains(KeyModifiers::CONTROL) => self.back(),
            KeyCode::Tab => {
                self.list_focus = !self.list_focus;
                self.aggregate.clear();
                if !self.list_focus
                    && let Some(index) = self.tile_index()
                {
                    self.select_tile(index);
                }
            }
            KeyCode::Char('/') => {
                self.query_before = self.query.clone();
                self.searching = true;
            }
            KeyCode::Esc => {
                self.query.clear();
                self.rebuild(true);
            }
            KeyCode::Char('?') => self.dialog = Some(Dialog::Help { scroll: 0 }),
            KeyCode::Char('a') => {
                if let Mode::Disk(state) = &mut self.mode {
                    state.apparent = !state.apparent;
                    self.rebuild(true);
                }
            }
            KeyCode::Char('d') => self.request_trash(),
            KeyCode::Char('r') => match &mut self.mode {
                Mode::Disk(_) => self.rescan(),
                Mode::Memory(state) => {
                    self.sort = SortOrder::Size;
                    let _ = state.sampler.commands.send(Command::Refresh);
                    self.status = "Taking a fresh sample and reordering…".into();
                    self.status_color = theme::BLUE;
                }
            },
            KeyCode::Char(' ') => {
                if let Mode::Memory(state) = &mut self.mode {
                    state.paused = !state.paused;
                    let _ = state.sampler.commands.send(Command::Pause(state.paused));
                    self.status = if state.paused { "Paused" } else { "Live" }.into();
                    self.status_color = if state.paused {
                        theme::SELECTED
                    } else {
                        theme::GREEN
                    };
                }
            }
            KeyCode::Char('v') => {
                if matches!(self.mode, Mode::Memory(_)) {
                    let view = if base_view(&self.view) == &View::System {
                        View::Apps
                    } else {
                        View::System
                    };
                    self.navigate(view);
                }
            }
            _ => {}
        }
    }

    fn title(&self) -> String {
        match &self.view {
            View::Disk(path) => format!("diskmap · {}", path.display()),
            View::Apps => "memmap · Apps".into(),
            View::System => "memmap · System".into(),
            View::Processes(id) => format!("memmap · Processes · {id}"),
            View::Other { ids, .. } => format!("Other · {} entries", ids.len()),
        }
    }

    fn usage_label(&self) -> String {
        match &self.mode {
            Mode::Disk(state) => {
                if state.apparent {
                    "Apparent bytes".into()
                } else {
                    "Allocated estimate · APFS clones, snapshots, compression affect reclaimable space".into()
                }
            }
            Mode::Memory(_) => {
                if base_view(&self.view) == &View::System {
                    "Physical RAM · non-overlapping OS categories".into()
                } else {
                    "Reported resident memory · shared pages may count more than once · % of process view".into()
                }
            }
        }
    }

    pub fn draw(&mut self, frame: &mut Frame<'_>) {
        let area = frame.area();
        frame.render_widget(
            Block::default().style(Style::default().bg(theme::BACKGROUND).fg(theme::FOREGROUND)),
            area,
        );
        let total: u64 = self.items.iter().map(|item| item.size).sum();
        let full = self.full_total;
        let total_label = if self.query.is_empty() {
            bytes(total)
        } else {
            format!("matched {} / full {}", bytes(total), bytes(full))
        };
        let paused = matches!(&self.mode, Mode::Memory(state) if state.paused);
        let header_height = if area.height >= 10 {
            2
        } else if area.height >= 2 {
            1
        } else {
            0
        };
        let footer_height = if area.height >= 18 && area.width >= 60 {
            3
        } else if area.height >= 8 {
            2
        } else if area.height >= 2 {
            1
        } else {
            0
        };
        if header_height > 0 {
            let title = self.title();
            let location = title
                .strip_prefix("diskmap · ")
                .or_else(|| title.strip_prefix("memmap · "))
                .unwrap_or(&title);
            frame.render_widget(
                Paragraph::new(Line::from(vec![
                    chrome::badge(
                        if matches!(self.mode, Mode::Disk(_)) {
                            "diskmap"
                        } else {
                            "memmap"
                        },
                        theme::BLUE,
                    ),
                    Span::styled(
                        format!(" {location} · "),
                        Style::default().fg(theme::FOREGROUND),
                    ),
                    Span::styled(
                        total_label,
                        Style::default()
                            .fg(theme::GREEN)
                            .add_modifier(Modifier::BOLD),
                    ),
                    if paused {
                        chrome::badge("PAUSED", theme::SELECTED)
                    } else {
                        Span::raw("")
                    },
                ])),
                Rect::new(area.x, area.y, area.width, area.height.min(1)),
            );
        }
        if header_height > 1 {
            frame.render_widget(
                Paragraph::new(Line::from(vec![
                    Span::styled(
                        self.sizing.description(),
                        Style::default().fg(theme::VIOLET),
                    ),
                    Span::styled(
                        format!(" · {}", self.usage_label()),
                        Style::default().fg(theme::DIM),
                    ),
                ])),
                Rect::new(area.x, area.y + 1, area.width, 1),
            );
        }
        let detail_height = if area.height >= 15 {
            5
        } else if area.height >= 10 {
            2
        } else {
            0
        };
        let reserved = header_height + detail_height + footer_height;
        let canvas = Rect::new(
            area.x,
            area.y + header_height,
            area.width,
            area.height.saturating_sub(reserved),
        );
        let only_list = treemap::list_only(canvas);
        let sidebar = !only_list && canvas.width >= 100;
        let show_full_list = only_list || (self.list_focus && !sidebar);
        let map_area = if sidebar {
            Rect::new(
                canvas.x,
                canvas.y,
                canvas.width.saturating_sub(32),
                canvas.height,
            )
        } else {
            canvas
        };
        self.geometry = if show_full_list {
            self.aggregate.clear();
            Vec::new()
        } else {
            if matches!(self.mode, Mode::Memory(_)) {
                self.stable_layout
                    .tiles_with_sizing(&self.items, map_area, self.sizing)
            } else {
                treemap::tiles_with_sizing(&self.items, map_area, self.sizing)
            }
        };
        if !self.list_focus
            && !show_full_list
            && let Some(tile) = self.tile_index()
        {
            self.select_tile(tile);
        }
        if show_full_list {
            self.draw_list(frame, canvas, total);
        } else {
            self.draw_map(frame, map_area);
            if sidebar {
                let list = Rect::new(map_area.right() + 1, canvas.y, 31, canvas.height);
                self.draw_list(frame, list, total);
            }
        }
        let details_y = canvas.bottom();
        let selected_details = self.detail_text(total, show_full_list);
        let available_details = area
            .bottom()
            .saturating_sub(details_y)
            .saturating_sub(footer_height)
            .min(detail_height);
        let memory_details = if let Mode::Memory(state) = &self.mode {
            state.snapshot.as_ref().map(|snapshot| {
                format!(
                    "RAM {} · available {} · swap {} / {}",
                    bytes(snapshot.ram),
                    bytes(snapshot.available),
                    bytes(snapshot.swap_used),
                    bytes(snapshot.swap_total),
                )
            })
        } else {
            None
        };
        let memory_height = if memory_details.is_some() {
            available_details.min(if area.width < 75 { 2 } else { 1 })
        } else {
            0
        };
        let trend = if self.aggregate.is_empty() {
            if let Mode::Memory(state) = &self.mode {
                self.selected.as_deref().and_then(|id| state.trends.get(id))
            } else {
                None
            }
        } else {
            None
        };
        let trend_height = u16::from(trend.is_some() && available_details > memory_height + 1);
        frame.render_widget(
            Paragraph::new(selected_details)
                .wrap(Wrap { trim: false })
                .style(if matches!(self.mode, Mode::Disk(_)) {
                    Style::default().fg(theme::FOREGROUND).bg(theme::SEPARATOR)
                } else {
                    Style::default()
                }),
            Rect::new(
                area.x,
                details_y,
                area.width,
                available_details - memory_height - trend_height,
            ),
        );
        if let Some(trend) = trend.filter(|_| trend_height > 0) {
            let y = details_y + available_details - memory_height - trend_height;
            let label = trend.label();
            let width = (label.chars().count() as u16 + 2).min(area.width.saturating_sub(8));
            let color = if trend.change() > 0 {
                theme::RED
            } else if trend.change() < 0 {
                theme::GREEN
            } else {
                theme::DIM
            };
            frame.render_widget(
                Paragraph::new(label).style(Style::default().fg(color)),
                Rect::new(area.x, y, width, 1),
            );
            let values = trend.recent(usize::from(area.width - width));
            let chart_width = values.len() as u16;
            frame.render_widget(
                Sparkline::default()
                    .data(&values)
                    .style(Style::default().fg(color)),
                Rect::new(area.right() - chart_width, y, chart_width, 1),
            );
        }
        if let Some(details) = memory_details {
            frame.render_widget(
                Paragraph::new(details)
                    .wrap(Wrap { trim: false })
                    .style(Style::default().fg(theme::DIM)),
                Rect::new(
                    area.x,
                    details_y + available_details - memory_height,
                    area.width,
                    memory_height,
                ),
            );
        }
        if footer_height >= 2 {
            let status = if self.searching {
                format!("/{}▏ · Enter applies · Esc cancels", self.query)
            } else if self.pending_g {
                "g… press g for the first entry".into()
            } else if !self.query.is_empty() {
                format!("filter /{} · {} · Esc clears", self.query, self.status)
            } else {
                self.status.clone()
            };
            let phase = match &self.mode {
                Mode::Disk(state) if state.scanner.is_some() => "SCAN ≈",
                Mode::Memory(state) if state.paused => "Ⅱ PAUSED",
                Mode::Memory(_) => "● LIVE",
                _ => "● READY",
            };
            frame.render_widget(
                Paragraph::new(Line::from(vec![
                    chrome::badge(
                        if self.list_focus || show_full_list {
                            "LIST"
                        } else {
                            "MAP"
                        },
                        theme::VIOLET,
                    ),
                    chrome::badge(phase, self.status_color),
                    Span::styled(
                        format!(" {status}"),
                        Style::default().fg(if matches!(self.mode, Mode::Disk(_)) {
                            self.status_color
                        } else {
                            theme::DIM
                        }),
                    ),
                ])),
                Rect::new(area.x, area.bottom() - footer_height, area.width, 1),
            );
            let primary = self.primary_hints(area.width);
            frame.render_widget(
                Paragraph::new(chrome::legend(&primary, area.width)),
                Rect::new(area.x, area.bottom() - footer_height + 1, area.width, 1),
            );
            if footer_height == 3 {
                frame.render_widget(
                    Paragraph::new(chrome::legend(&self.secondary_hints(), area.width)),
                    Rect::new(area.x, area.bottom() - 1, area.width, 1),
                );
            }
        } else if footer_height == 1 {
            frame.render_widget(
                Paragraph::new(if self.searching {
                    format!("/{}▏", self.query)
                } else {
                    String::new()
                })
                .style(Style::default().fg(theme::DIM)),
                Rect::new(area.x, area.bottom() - 1, area.width, 1),
            );
            if !self.searching {
                frame.render_widget(
                    Paragraph::new(chrome::legend(&self.primary_hints(area.width), area.width)),
                    Rect::new(area.x, area.bottom() - 1, area.width, 1),
                );
            }
        }
        if let Some(dialog) = &self.dialog {
            draw_dialog(frame, dialog, matches!(self.mode, Mode::Disk(_)));
        }
    }

    fn sort_label(&self) -> &'static str {
        if self.sort == SortOrder::Size {
            "size ↓"
        } else {
            "name ↑"
        }
    }

    fn detail_text(&self, total: u64, show_full_list: bool) -> Text<'static> {
        let grouped = !self.aggregate.is_empty() && !self.list_focus && !show_full_list;
        let (name, size, detail) = if grouped {
            (
                format!("Other · {} entries", self.aggregate.len()),
                self.items
                    .iter()
                    .filter(|item| self.aggregate.contains(&item.id))
                    .map(|item| item.size)
                    .sum(),
                "Enter opens this collection; Tab selects individual entries".to_owned(),
            )
        } else if let Some(index) = self.selected_index() {
            let item = &self.items[index];
            (item.name.clone(), item.size, item.detail.clone())
        } else {
            return Text::styled(self.empty_details(), Style::default().fg(theme::SELECTED));
        };
        let Mode::Disk(state) = &self.mode else {
            return Text::from(format!(
                "{name} · {} · {:.1}%\n{detail}",
                bytes(size),
                percentage(size, total)
            ));
        };
        let mut lines = vec![Line::from(vec![
            chrome::badge(&name, theme::BLUE),
            Span::styled(
                format!("  {} ", bytes(size)),
                Style::default().fg(theme::GREEN).bold(),
            ),
            Span::styled(
                format!(" · {:.1}%", percentage(size, total)),
                Style::default().fg(theme::VIOLET),
            ),
        ])];
        let node = (!grouped)
            .then(|| self.selected.as_deref().and_then(crate::disk::path_from_id))
            .flatten()
            .and_then(|path| {
                state
                    .tree_for(&path)
                    .and_then(|tree| tree.paths.get(&path).map(|index| &tree.nodes[*index]))
            });
        if let Some(node) = node {
            lines.push(Line::from(Span::styled(
                format!(" {}", node.path.display()),
                Style::default().fg(theme::BLUE),
            )));
            lines.push(Line::from(vec![
                chrome::badge(
                    if node.symlink {
                        "Symlink"
                    } else if node.directory {
                        "Folder"
                    } else {
                        "File"
                    },
                    theme::VIOLET,
                ),
                Span::styled(" allocated ", Style::default().fg(theme::SELECTED)),
                Span::styled(bytes(node.allocated), Style::default().fg(theme::GREEN)),
                Span::styled(" · apparent ", Style::default().fg(theme::BLUE)),
                Span::styled(bytes(node.apparent), Style::default().fg(theme::GREEN)),
            ]));
            if !node.notes.is_empty() {
                lines.push(Line::from(Span::styled(
                    format!(" {}", node.notes.join("; ")),
                    Style::default().fg(if node.incomplete {
                        theme::SELECTED
                    } else {
                        theme::VIOLET
                    }),
                )));
            }
        } else {
            lines.push(Line::from(Span::styled(
                format!(" {detail}"),
                Style::default().fg(theme::SELECTED),
            )));
        }
        Text::from(lines)
    }

    fn primary_hints(&self, width: u16) -> Vec<Hint> {
        if self.searching {
            return vec![
                Hint::new("↵", "apply", theme::GREEN),
                Hint::new("esc", "cancel", theme::SELECTED),
            ];
        }
        if width < 45 {
            return vec![
                Hint::new("q", "quit", theme::RED),
                Hint::new("?", "help", theme::BLUE),
                Hint::new("tab", "list", theme::VIOLET),
            ];
        }
        let mut hints = vec![
            Hint::new("hjkl", "nav", theme::BLUE),
            Hint::new("↵", "open", theme::GREEN),
            Hint::new("tab", "focus", theme::VIOLET),
            Hint::new("^o", "back", theme::BLUE),
            Hint::new("/", "find", theme::SELECTED),
            Hint::new("?", "help", theme::BLUE),
            Hint::new("q", "quit", theme::RED),
        ];
        if width < 80 {
            hints.rotate_right(2);
        }
        hints
    }

    fn secondary_hints(&self) -> Vec<Hint> {
        let mut hints = match &self.mode {
            Mode::Disk(state) => vec![
                Hint::new(
                    "a",
                    if state.apparent {
                        "apparent"
                    } else {
                        "allocated"
                    },
                    theme::SELECTED,
                ),
                Hint::new("r", "rescan", theme::GREEN),
                Hint::new("d", "trash", theme::RED),
            ],
            Mode::Memory(state) => vec![
                Hint::new(
                    "space",
                    if state.paused { "resume" } else { "pause" },
                    theme::SELECTED,
                ),
                Hint::new(
                    "v",
                    if base_view(&self.view) == &View::System {
                        "apps"
                    } else {
                        "system"
                    },
                    theme::VIOLET,
                ),
                Hint::new("r", "refresh", theme::GREEN),
            ],
        };
        hints.extend([
            Hint::new("b", self.sizing.label(), theme::VIOLET),
            Hint::new("s", self.sort_label(), theme::SELECTED),
            Hint::new("gg/G", "ends", theme::BLUE),
            Hint::new("pg↑↓", "page", theme::BLUE),
            Hint::new("y", "copy", theme::GREEN),
        ]);
        hints
    }

    fn draw_map(&self, frame: &mut Frame<'_>, area: Rect) {
        let selected_tile = self.tile_index();
        for (index, tile) in self.geometry.iter().enumerate() {
            if tile.rect.is_empty() {
                continue;
            }
            let grouped = tile.members.len() > 1;
            let first = &self.items[tile.members[0]];
            let (name, size, color) = if grouped {
                (
                    format!("Other · {} entries", tile.members.len()),
                    tile.members.iter().map(|i| self.items[*i].size).sum(),
                    theme::color("other"),
                )
            } else {
                (first.name.clone(), first.size, theme::color(&first.id))
            };
            let selected = Some(index) == selected_tile;
            let border = if selected {
                theme::SELECTED
            } else {
                theme::SEPARATOR
            };
            let block = Block::default()
                .borders(Borders::ALL)
                .border_type(BorderType::Rounded)
                .border_style(Style::default().fg(border))
                .style(Style::default().bg(color).fg(theme::INK));
            let inner = block.inner(tile.rect);
            frame.render_widget(block, tile.rect);
            if !inner.is_empty() {
                frame.render_widget(
                    Paragraph::new(vec![
                        Line::from(Span::styled(
                            name,
                            Style::default().add_modifier(Modifier::BOLD),
                        )),
                        Line::from(bytes(size)),
                    ])
                    .wrap(Wrap { trim: false })
                    .style(Style::default().bg(color).fg(theme::INK)),
                    inner,
                );
            }
        }
        if self.geometry.is_empty() {
            frame.render_widget(
                Paragraph::new("No drawable bytes · Tab opens the list"),
                area,
            );
        }
    }

    fn empty_details(&self) -> String {
        if !self.query.is_empty() {
            return "No search matches · Esc clears the filter".into();
        }
        match (&self.mode, base_view(&self.view)) {
            (Mode::Disk(state), View::Disk(path)) => {
                if let Some(node) = state
                    .tree_for(path)
                    .and_then(|tree| tree.paths.get(path).map(|i| &tree.nodes[*i]))
                {
                    if state.scanner.is_some() {
                        return "Waiting for scan results · totals are provisional".into();
                    }
                    return if !node.incomplete {
                        "Empty folder".into()
                    } else {
                        format!("Incomplete folder totals\n{}", node.notes.join("; "))
                    };
                }
                "Scanning… · input remains available".into()
            }
            (Mode::Memory(_), View::Processes(_)) => {
                "No reported processes remain for this app · Ctrl+O returns".into()
            }
            (Mode::Memory(_), View::System) => {
                "System breakdown unavailable · see status warning".into()
            }
            _ => "No entries reported".into(),
        }
    }

    fn draw_list(&mut self, frame: &mut Frame<'_>, area: Rect, total: u64) {
        let selected = self.selected_index();
        self.list_state.select(selected);
        self.list_page = usize::from(if area.height >= 3 {
            area.height - 2
        } else {
            area.height
        })
        .max(1);
        let mut offset = self
            .list_state
            .offset()
            .min(self.items.len().saturating_sub(self.list_page));
        if let Some(selected) = selected {
            if selected < offset {
                offset = selected;
            }
            if selected >= offset + self.list_page {
                offset = selected + 1 - self.list_page;
            }
        }
        *self.list_state.offset_mut() = offset;
        let rows = self
            .items
            .iter()
            .skip(offset)
            .take(self.list_page)
            .map(|item| {
                ListItem::new(Line::from(vec![
                    Span::styled(
                        item.name.clone(),
                        Style::default().fg(theme::color(&item.id)),
                    ),
                    Span::styled(
                        format!("  {}", bytes(item.size)),
                        Style::default().fg(theme::GREEN),
                    ),
                    Span::styled(
                        format!("  {:.1}%", percentage(item.size, total)),
                        Style::default().fg(theme::DIM),
                    ),
                ]))
            });
        let mut list = List::new(rows).highlight_symbol("› ").highlight_style(
            Style::default()
                .bg(theme::SEPARATOR)
                .add_modifier(Modifier::BOLD),
        );
        if area.height >= 3 {
            list = list.block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_type(BorderType::Rounded)
                    .border_style(Style::default().fg(if self.list_focus {
                        theme::BLUE
                    } else {
                        theme::BORDER
                    }))
                    .title(format!(" Entries · {} ", self.sort_label()))
                    .title_bottom(format!(
                        " {}/{} ",
                        selected.map_or(0, |i| i + 1),
                        self.items.len()
                    )),
            );
        }
        let mut visible_state =
            ListState::default().with_selected(selected.map(|index| index - offset));
        frame.render_stateful_widget(list, area, &mut visible_state);
    }
}

fn percentage(size: u64, total: u64) -> f64 {
    if total == 0 {
        0.0
    } else {
        size as f64 / total as f64 * 100.0
    }
}

fn base_view(view: &View) -> &View {
    if let View::Other { parent, .. } = view {
        base_view(parent)
    } else {
        view
    }
}

fn repair_disk_view(view: &mut View, tree: &Tree, root: &std::path::Path) {
    match view {
        View::Disk(path) => {
            while !tree.paths.contains_key(path) {
                if !path.pop() || !path.starts_with(root) {
                    *path = root.to_owned();
                    break;
                }
            }
        }
        View::Other { parent, .. } => repair_disk_view(parent, tree, root),
        _ => {}
    }
}

pub fn preserve_order(items: &mut [Item], previous: &[Item]) {
    let positions: HashMap<&str, usize> = previous
        .iter()
        .enumerate()
        .map(|(i, item)| (item.id.as_str(), i))
        .collect();
    items.sort_by(|a, b| {
        positions
            .get(a.id.as_str())
            .unwrap_or(&usize::MAX)
            .cmp(positions.get(b.id.as_str()).unwrap_or(&usize::MAX))
    });
}

fn draw_dialog(frame: &mut Frame<'_>, dialog: &Dialog, disk: bool) {
    let area = frame.area();
    let width = area.width.saturating_sub(4).min(96).max(area.width.min(10));
    let height = area
        .height
        .saturating_sub(2)
        .min(25)
        .max(area.height.min(5));
    let popup = Rect::new(
        area.x + (area.width - width) / 2,
        area.y + (area.height - height) / 2,
        width,
        height,
    );
    let (title, body, scroll) = match dialog {
        Dialog::Help { scroll } => (" Help ", String::new(), *scroll),
        Dialog::Details {
            title,
            body,
            scroll,
        } => (title.as_str(), body.clone(), *scroll),
        Dialog::Trash { request, scroll } => (
            " Move to Trash? ",
            format!(
                "{}\n\n{}\n\nMove this entry and its contents to Trash?\nSpace may remain used until Trash is emptied.\nNo permanent-delete fallback.",
                request.path.display(),
                bytes(request.size)
            ),
            *scroll,
        ),
    };
    frame.render_widget(Clear, popup);
    let block = Block::default()
        .title(title)
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .border_style(Style::default().fg(theme::SELECTED))
        .style(Style::default().bg(theme::BACKGROUND).fg(theme::FOREGROUND));
    let inner = block.inner(popup);
    frame.render_widget(block, popup);
    frame.render_widget(
        if matches!(dialog, Dialog::Help { .. }) {
            Paragraph::new(chrome::help(disk))
        } else {
            Paragraph::new(body)
        }
        .wrap(Wrap { trim: false })
        .scroll((scroll, 0)),
        Rect::new(
            inner.x,
            inner.y,
            inner.width,
            inner.height.saturating_sub(1),
        ),
    );
    if inner.height > 0 {
        let hints = if matches!(dialog, Dialog::Trash { .. }) {
            vec![
                Hint::new("y", "confirm", theme::GREEN),
                Hint::new("n/esc", "cancel", theme::RED),
                Hint::new("j/k", "scroll", theme::BLUE),
            ]
        } else {
            vec![
                Hint::new("j/k", "scroll", theme::BLUE),
                Hint::new("esc", "close", theme::SELECTED),
            ]
        };
        frame.render_widget(
            Paragraph::new(chrome::legend(&hints, inner.width)),
            Rect::new(inner.x, inner.bottom() - 1, inner.width, 1),
        );
    }
}

pub fn run(mut app: AppState) -> Result<()> {
    let (sender, receiver) = mpsc::sync_channel(8);
    app.wake.attach(sender.clone());
    crate::terminal::with_terminal(|terminal| {
        let input_sender = sender.clone();
        thread::spawn(move || {
            loop {
                let input = match event::read() {
                    Ok(event) => AppEvent::Terminal(event),
                    Err(error) => {
                        let _ = input_sender.send(AppEvent::InputError(error.to_string()));
                        return;
                    }
                };
                if input_sender.send(input).is_err() {
                    return;
                }
            }
        });
        let mut redraw = true;
        loop {
            redraw |= app.update();
            if redraw {
                terminal.draw(|frame| app.draw(frame))?;
                redraw = false;
            }
            if let Some(text) = app.pending_copy.take() {
                let sender = sender.clone();
                thread::spawn(move || {
                    let native =
                        crate::clipboard::copy_native(&text).map_err(|error| error.to_string());
                    let _ = sender.send(AppEvent::Clipboard { text, native });
                });
            }
            if app.quit {
                return Ok(());
            }
            match receiver.recv().context("UI event stream closed")? {
                AppEvent::Terminal(Event::Key(key)) => {
                    app.key(key);
                    redraw = true;
                }
                AppEvent::Terminal(Event::Resize(..)) => redraw = true,
                AppEvent::InputError(error) => bail!("Terminal input failed: {error}"),
                AppEvent::Clipboard { text, native } => {
                    app.copying = false;
                    if matches!(native, Ok(true)) {
                        app.status = "Path copied to clipboard".into();
                        app.status_color = theme::GREEN;
                    } else {
                        crate::clipboard::copy(&text, io::stdout().lock())?;
                        app.status =
                            "OSC 52 copy requested · your terminal must allow clipboard access"
                                .into();
                        app.status_color = theme::SELECTED;
                    }
                    redraw = true;
                }
                _ => {}
            }
        }
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use ratatui::{Terminal, backend::TestBackend};
    use std::sync::atomic::AtomicBool;
    use std::time::Instant;

    fn disk_app() -> (tempfile::TempDir, AppState) {
        let dir = tempfile::tempdir().unwrap();
        std::fs::write(dir.path().join("large"), vec![0; 32_768]).unwrap();
        std::fs::create_dir(dir.path().join("nested")).unwrap();
        std::fs::write(dir.path().join("nested/file"), vec![0; 8_192]).unwrap();
        std::fs::write(dir.path().join("empty"), []).unwrap();
        let root = dir.path().canonicalize().unwrap();
        let tree = crate::disk::scan(&root, &AtomicBool::new(false), |_, _| {})
            .unwrap()
            .unwrap();
        let mut app = AppState::new(
            Mode::Disk(DiskState {
                root: root.clone(),
                tree: Some(tree),
                preview: None,
                scanner: None,
                apparent: true,
                trash_job: None,
            }),
            View::Disk(root),
            "Ready".into(),
        );
        app.rebuild(true);
        (dir, app)
    }

    fn key(code: KeyCode) -> KeyEvent {
        KeyEvent::new(code, KeyModifiers::NONE)
    }

    #[test]
    fn ordering_and_selection_survive_live_updates() {
        let previous = vec![
            Item {
                id: "a".into(),
                name: "a".into(),
                size: 20,
                detail: String::new(),
            },
            Item {
                id: "b".into(),
                name: "b".into(),
                size: 10,
                detail: String::new(),
            },
        ];
        let mut next = vec![previous[1].clone(), previous[0].clone()];
        preserve_order(&mut next, &previous);
        assert_eq!(next[0].id, "a");
        next.retain(|item| item.id != "a");
        preserve_order(&mut next, &previous);
        assert_eq!(next[0].id, "b");
    }

    #[test]
    fn filter_navigation_and_zero_entries() {
        let (_dir, mut app) = disk_app();
        app.list_focus = true;
        app.selected = app
            .items
            .iter()
            .find(|i| i.name == "nested/")
            .map(|i| i.id.clone());
        app.key(key(KeyCode::Enter));
        assert_eq!(app.items.len(), 1);
        app.key(key(KeyCode::Backspace));
        assert_eq!(app.items.len(), 3);
        assert!(
            crate::disk::path_from_id(app.selected.as_ref().unwrap())
                .unwrap()
                .ends_with("nested")
        );
        app.key(key(KeyCode::Char('/')));
        app.key(key(KeyCode::Char('e')));
        app.key(key(KeyCode::Char('m')));
        assert_eq!(app.items.len(), 1);
        assert_eq!(app.items[0].size, 0);
        app.key(key(KeyCode::Esc));
        assert_eq!(app.items.len(), 3);
    }

    #[test]
    fn scanning_keeps_navigation_and_quit_available() {
        let (_dir, mut app) = disk_app();
        app.rescan();
        assert!(matches!(&app.mode, Mode::Disk(state) if state.scanner.is_some()));
        app.key(key(KeyCode::Tab));
        app.key(key(KeyCode::Char('j')));
        assert_eq!(app.selected_index(), Some(1));
        app.key(key(KeyCode::Enter));
        assert!(matches!(&app.view, View::Disk(path) if path.ends_with("nested")));
        app.key(key(KeyCode::Char('q')));
        assert!(app.quit);
    }

    #[test]
    fn ctrl_o_at_launch_root_scans_parent_and_preserves_selection() {
        for scanning in [false, true] {
            let (dir, mut app) = disk_app();
            let parent = dir.path().canonicalize().unwrap();
            let root = parent.join("nested");
            if let Mode::Disk(state) = &mut app.mode {
                state.root = root.clone();
                state.tree = crate::disk::scan(&root, &AtomicBool::new(false), |_, _| {}).unwrap();
            }
            app.view = View::Disk(root.clone());
            app.selected = None;
            app.rebuild(true);
            if scanning {
                app.rescan();
            }
            app.query = "file".into();
            app.key(KeyEvent::new(KeyCode::Char('o'), KeyModifiers::CONTROL));
            assert_eq!(app.view, View::Disk(parent.clone()));
            assert_eq!(app.selected, Some(crate::disk::path_id(&root)));
            assert!(app.query.is_empty());
            assert!(app.history.is_empty());
            assert!(matches!(&app.mode, Mode::Disk(state)
                if state.root == parent && state.scanner.is_some()));
            let deadline = Instant::now() + Duration::from_secs(5);
            while matches!(&app.mode, Mode::Disk(state) if state.scanner.is_some()) {
                app.update();
                assert!(Instant::now() < deadline, "Parent scan did not finish");
                thread::sleep(Duration::from_millis(5));
            }
            assert_eq!(app.items.len(), 3);
            assert_eq!(app.selected, Some(crate::disk::path_id(&root)));
            app.list_focus = true;
            app.key(key(KeyCode::Enter));
            assert_eq!(app.view, View::Disk(root));
            app.key(key(KeyCode::Backspace));
            assert_eq!(app.view, View::Disk(parent.clone()));
            assert!(matches!(&app.mode, Mode::Disk(state) if state.scanner.is_none()));
            app.rescan();
            assert!(matches!(&app.mode, Mode::Disk(state)
                if state.root == parent && state.scanner.is_some()));
        }
    }

    #[test]
    fn parent_navigation_uses_cache_and_stops_at_filesystem_root() {
        let (_dir, mut app) = disk_app();
        let View::Disk(root) = app.view.clone() else {
            unreachable!()
        };
        let nested = root.join("nested");
        app.view = View::Disk(nested.clone());
        app.key(key(KeyCode::Backspace));
        assert_eq!(app.view, View::Disk(root.clone()));
        assert_eq!(app.selected, Some(crate::disk::path_id(&nested)));
        assert!(matches!(&app.mode, Mode::Disk(state) if state.scanner.is_none()));
        app.view = View::Disk(PathBuf::from("/"));
        app.key(KeyEvent::new(KeyCode::Char('o'), KeyModifiers::CONTROL));
        assert_eq!(app.view, View::Disk(PathBuf::from("/")));
        assert!(app.status.contains("filesystem root"));
        assert!(matches!(&app.mode, Mode::Disk(state)
            if state.root == root && state.scanner.is_none()));
    }

    #[test]
    fn disk_detail_panel_renders_semantic_colors_and_warnings() {
        let (_dir, mut app) = disk_app();
        let selected = app.selected.clone().unwrap();
        if let Mode::Disk(state) = &mut app.mode {
            let tree = state.tree.as_mut().unwrap();
            let path = crate::disk::path_from_id(&selected).unwrap();
            let node = &mut tree.nodes[*tree.paths.get(&path).unwrap()];
            node.incomplete = true;
            node.notes.push("Permission denied".into());
        }
        let mut terminal = Terminal::new(TestBackend::new(110, 24)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let buffer = terminal.backend().buffer();
        let assert_text_color = |y: u16, text: &str, color: Color| {
            let row = (0..110)
                .map(|x| buffer[(x, y)].symbol())
                .collect::<String>();
            let x = row[..row.find(text).unwrap()].chars().count() as u16;
            assert_eq!(buffer[(x, y)].fg, color, "{text}");
            assert_eq!(buffer[(x, y)].bg, theme::SEPARATOR, "{text}");
        };
        assert_text_color(16, "large", theme::BLUE);
        assert_text_color(16, "32.0 KiB", theme::GREEN);
        assert_text_color(16, "80.0%", theme::VIOLET);
        assert_text_color(17, "/", theme::BLUE);
        assert_text_color(18, "File", theme::VIOLET);
        assert_text_color(18, "allocated", theme::SELECTED);
        assert_text_color(18, "apparent", theme::BLUE);
        assert_text_color(19, "Permission denied", theme::SELECTED);
        let status_row = (0..110)
            .map(|x| buffer[(x, 21)].symbol())
            .collect::<String>();
        let status_x = status_row[..status_row.find("Ready").unwrap()]
            .chars()
            .count() as u16;
        assert_eq!(buffer[(status_x, 21)].fg, app.status_color);
    }

    #[test]
    fn sizing_toggle_changes_tiles_without_changing_usage_or_selection() {
        let (_dir, mut app) = disk_app();
        let selected = app.selected.clone();
        let items = app.items.clone();
        let total = app.full_total;
        let mut terminal = Terminal::new(TestBackend::new(110, 24)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let balanced: Vec<_> = app.geometry.iter().map(|tile| tile.rect).collect();
        assert_eq!(app.sizing, Sizing::Balanced);
        app.key(key(KeyCode::Char('b')));
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let proportional: Vec<_> = app.geometry.iter().map(|tile| tile.rect).collect();
        assert_eq!(app.sizing, Sizing::Proportional);
        assert_ne!(balanced, proportional);
        assert_eq!(app.selected, selected);
        assert_eq!(app.items, items);
        assert_eq!(app.full_total, total);
        app.key(key(KeyCode::Char('b')));
        terminal.draw(|frame| app.draw(frame)).unwrap();
        assert_eq!(
            balanced,
            app.geometry
                .iter()
                .map(|tile| tile.rect)
                .collect::<Vec<_>>()
        );
        assert!(matches!(&app.mode, Mode::Disk(state) if state.scanner.is_none()));
    }

    #[test]
    fn tiny_terminals_render_without_panics() {
        let (_dir, mut app) = disk_app();
        for (width, height) in [(1, 1), (10, 3), (25, 8), (80, 24), (120, 30)] {
            let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
            terminal.draw(|frame| app.draw(frame)).unwrap();
            if width < 35 {
                assert!(app.geometry.is_empty());
            }
        }
    }

    fn synthetic_snapshot(processes: &[(u32, u64, u64)]) -> Snapshot {
        Snapshot {
            apps: crate::memory::group_processes(
                processes
                    .iter()
                    .map(|(pid, started, resident)| crate::memory::Process {
                        pid: *pid,
                        started: *started,
                        name: "Editor".into(),
                        executable: Some(PathBuf::from(
                            "/Applications/Editor.app/Contents/MacOS/editor",
                        )),
                        command: Some("editor --session demo".into()),
                        resident: *resident,
                    })
                    .collect(),
                true,
            ),
            ram: 1024 * 1024,
            available: 256 * 1024,
            swap_used: 0,
            swap_total: 512 * 1024,
            breakdown: Some(
                crate::memory::account(
                    1024 * 1024,
                    &[
                        ("Free", 128 * 1024),
                        ("Active", 256 * 1024),
                        ("Inactive", 256 * 1024),
                        ("Wired", 128 * 1024),
                        ("Compressed", 64 * 1024),
                    ],
                    "Speculative and purgeable pages already belong to categories".into(),
                )
                .unwrap(),
            ),
            warning: None,
            taken: Instant::now(),
            requested: false,
        }
    }

    fn memory_app() -> (mpsc::SyncSender<Snapshot>, AppState) {
        let (sender, snapshots) = mpsc::sync_channel(2);
        let (commands, _) = mpsc::channel();
        let mut app = AppState::new(
            Mode::Memory(MemoryState {
                sampler: Sampler {
                    snapshots,
                    commands,
                    wake: Wake::default(),
                },
                snapshot: None,
                paused: false,
                trends: History::default(),
            }),
            View::Apps,
            "Live".into(),
        );
        sender
            .send(synthetic_snapshot(&[
                (42, 100, 32 * 1024),
                (43, 200, 8 * 1024),
            ]))
            .unwrap();
        app.update();
        (sender, app)
    }

    #[test]
    fn memory_selection_order_pause_pid_reuse_and_exit() {
        let (sender, mut app) = memory_app();
        app.key(key(KeyCode::Enter));
        assert!(matches!(app.view, View::Processes(_)));
        app.list_focus = true;
        app.selected = Some("pid:43:200".into());
        sender
            .send(synthetic_snapshot(&[(42, 100, 10), (43, 200, 90)]))
            .unwrap();
        app.update();
        assert_eq!(app.items[0].id, "pid:42:100");
        assert_eq!(app.selected.as_deref(), Some("pid:43:200"));
        app.key(key(KeyCode::Char(' ')));
        sender
            .send(synthetic_snapshot(&[(42, 100, 30), (43, 200, 100)]))
            .unwrap();
        app.update();
        assert_eq!(app.items[0].size, 10);
        let mut refreshed = synthetic_snapshot(&[(42, 100, 30), (43, 200, 100)]);
        refreshed.requested = true;
        sender.send(refreshed).unwrap();
        app.update();
        assert_eq!(app.items[0].id, "pid:43:200");
        assert_eq!(app.selected.as_deref(), Some("pid:43:200"));
        app.key(key(KeyCode::Char(' ')));
        sender
            .send(synthetic_snapshot(&[(42, 100, 30), (43, 201, 100)]))
            .unwrap();
        app.update();
        assert!(!app.items.iter().any(|i| i.id == "pid:43:200"));
        assert_ne!(app.selected.as_deref(), Some("pid:43:200"));
        sender.send(synthetic_snapshot(&[])).unwrap();
        app.update();
        assert!(app.items.is_empty());
        assert!(app.empty_details().contains("No reported processes remain"));
        app.key(key(KeyCode::Backspace));
        assert_eq!(app.view, View::Apps);
    }

    #[test]
    fn memory_labels_use_process_total_and_system_uses_physical_total() {
        let (_sender, mut app) = memory_app();
        assert_eq!(app.full_total, 40 * 1024);
        assert!(app.usage_label().contains("shared pages"));
        assert!(app.usage_label().contains("% of process view"));
        app.key(key(KeyCode::Char('v')));
        assert_eq!(app.view, View::System);
        assert_eq!(app.full_total, 1024 * 1024);
        assert!(app.usage_label().contains("non-overlapping"));
        assert!(app.items.iter().all(|i| !i.name.contains("purgeable")));
    }

    #[test]
    fn trash_dialog_requires_y_and_escape_cancels() {
        let (_dir, mut app) = disk_app();
        app.list_focus = true;
        app.key(key(KeyCode::Char('d')));
        assert!(matches!(app.dialog, Some(Dialog::Trash { .. })));
        app.key(key(KeyCode::Enter));
        assert!(matches!(app.dialog, Some(Dialog::Trash { .. })));
        assert!(matches!(&app.mode, Mode::Disk(state) if state.trash_job.is_none()));
        app.key(key(KeyCode::Esc));
        assert!(app.dialog.is_none());
        app.aggregate = app.items.iter().map(|i| i.id.clone()).collect();
        app.list_focus = false;
        app.key(key(KeyCode::Char('d')));
        assert!(app.dialog.is_none());
        assert!(app.status.contains("select a real entry"));
        app.key(key(KeyCode::Char('?')));
        app.key(key(KeyCode::Char('q')));
        assert!(app.quit);
    }

    #[test]
    fn other_opens_as_list_and_missing_folder_returns_to_parent() {
        let (_dir, mut app) = disk_app();
        app.aggregate = app.items.iter().map(|i| i.id.clone()).collect();
        app.key(key(KeyCode::Enter));
        assert!(matches!(app.view, View::Other { .. }));
        assert!(app.list_focus);
        app.key(key(KeyCode::Backspace));
        let Mode::Disk(state) = &app.mode else {
            unreachable!()
        };
        let mut view = View::Disk(state.root.join("gone/nested"));
        repair_disk_view(&mut view, state.tree.as_ref().unwrap(), &state.root);
        assert_eq!(view, View::Disk(state.root.clone()));
    }

    #[test]
    fn list_paging_sorting_and_copy_keep_item_identity() {
        let (dir, mut app) = disk_app();
        for index in 0..30 {
            std::fs::write(dir.path().join(format!("entry-{index:02}")), []).unwrap();
        }
        if let Mode::Disk(state) = &mut app.mode {
            state.tree =
                crate::disk::scan(&state.root, &AtomicBool::new(false), |_, _| {}).unwrap();
        }
        app.rebuild(true);
        app.list_focus = true;
        let mut terminal = Terminal::new(TestBackend::new(60, 12)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        assert_eq!(app.list_page, 4);
        app.key(key(KeyCode::PageDown));
        assert_eq!(app.selected_index(), Some(4));
        app.key(key(KeyCode::PageUp));
        assert_eq!(app.selected_index(), Some(0));
        app.key(key(KeyCode::Char('G')));
        assert_eq!(app.selected_index(), Some(32));
        terminal.draw(|frame| app.draw(frame)).unwrap();
        assert_eq!(app.list_state.offset(), 29);
        let visible = (0..12)
            .map(|y| {
                (0..60)
                    .map(|x| terminal.backend().buffer()[(x, y)].symbol())
                    .collect::<String>()
            })
            .collect::<Vec<_>>()
            .join("\n");
        assert!(visible.contains("entry-29"));
        assert!(!visible.contains("entry-00"));
        app.key(key(KeyCode::Char('g')));
        app.key(key(KeyCode::Char('g')));
        assert_eq!(app.selected_index(), Some(0));
        terminal.draw(|frame| app.draw(frame)).unwrap();
        assert_eq!(app.list_state.offset(), 0);
        let selected = app.selected.clone();
        app.key(key(KeyCode::Char('s')));
        assert!(app.sort == SortOrder::Name);
        assert_eq!(app.items[0].name, "empty");
        assert_eq!(app.selected, selected);
        app.key(key(KeyCode::Char('y')));
        assert_eq!(
            app.pending_copy.take().unwrap(),
            dir.path()
                .canonicalize()
                .unwrap()
                .join("large")
                .to_str()
                .unwrap()
        );
        app.key(key(KeyCode::Char('y')));
        assert!(app.pending_copy.is_none());
    }

    #[test]
    fn partial_tree_can_be_navigated_without_an_empty_folder_claim() {
        let (_dir, mut app) = disk_app();
        if let Mode::Disk(state) = &mut app.mode {
            let mut preview = state.tree.take().unwrap();
            preview.nodes.truncate(4);
            preview.paths.retain(|_, index| *index < 4);
            for node in &mut preview.nodes {
                node.children.retain(|index| *index < 4);
            }
            preview.nodes[3].allocated = 0;
            preview.nodes[3].apparent = 0;
            state.preview = Some(preview);
            state.scanner = Some(Scanner::start(state.root.clone()));
        }
        app.rebuild(false);
        app.list_focus = true;
        app.selected = app
            .items
            .iter()
            .find(|item| item.name == "nested/")
            .map(|item| item.id.clone());
        app.key(key(KeyCode::Enter));
        assert!(matches!(&app.view, View::Disk(path) if path.ends_with("nested")));
        assert!(app.items.is_empty());
        assert!(app.empty_details().contains("provisional"));
        app.key(key(KeyCode::Char('d')));
        assert!(app.dialog.is_none());
        assert!(app.status.contains("scan to finish"));
        app.key(key(KeyCode::Backspace));
        assert_eq!(app.items.len(), 3);
    }

    #[test]
    fn history_tracks_growth_and_discards_exited_processes() {
        let (sender, mut app) = memory_app();
        sender
            .send(synthetic_snapshot(&[
                (42, 100, 64 * 1024),
                (43, 200, 8 * 1024),
            ]))
            .unwrap();
        app.update();
        let Mode::Memory(state) = &app.mode else {
            unreachable!()
        };
        let app_id = &state.snapshot.as_ref().unwrap().apps[0].id;
        assert_eq!(state.trends.get(app_id).unwrap().change(), 32 * 1024);
        assert_eq!(state.trends.get("pid:42:100").unwrap().change(), 32 * 1024);
        sender
            .send(synthetic_snapshot(&[(43, 201, 8 * 1024)]))
            .unwrap();
        app.update();
        let Mode::Memory(state) = &app.mode else {
            unreachable!()
        };
        assert!(state.trends.get("pid:42:100").is_none());
        assert!(state.trends.get("pid:43:200").is_none());
        assert_eq!(state.trends.get("pid:43:201").unwrap().change(), 0);
    }

    fn snapshot(app: &mut AppState, name: &str, width: u16, height: u16) {
        let mut terminal = Terminal::new(TestBackend::new(width, height)).unwrap();
        terminal.draw(|frame| app.draw(frame)).unwrap();
        let buffer = terminal.backend().buffer();
        let text = (0..height)
            .map(|y| {
                (0..width)
                    .map(|x| buffer[(x, y)].symbol())
                    .collect::<String>()
                    .trim_end()
                    .to_owned()
            })
            .collect::<Vec<_>>()
            .join("\n")
            + "\n";
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("tests/snapshots")
            .join(format!("{name}.txt"));
        if std::env::var_os("UPDATE_SNAPSHOTS").is_some() {
            std::fs::create_dir_all(path.parent().unwrap()).unwrap();
            std::fs::write(&path, &text).unwrap();
            if name == "memory-apps" || name == "disk-wide" || name == "help" {
                std::fs::write(
                    path.with_extension("svg"),
                    render_svg(buffer, width, height),
                )
                .unwrap();
            }
        }
        assert_eq!(text, std::fs::read_to_string(path).unwrap());
        assert_eq!(buffer[(0, 0)].fg, theme::BLUE);
        assert_eq!(buffer[(0, 0)].bg, theme::SEPARATOR);
        if !app.geometry.is_empty() && app.dialog.is_none() {
            for tile in &app.geometry {
                if tile.rect.width > 2 && tile.rect.height > 2 {
                    let fill = buffer[(tile.rect.x + 1, tile.rect.y + 1)].bg;
                    assert!(theme::FILLS.contains(&fill));
                }
            }
        }
    }

    fn render_svg(buffer: &ratatui::buffer::Buffer, width: u16, height: u16) -> String {
        let rgb = |color: Color| match color {
            Color::Rgb(r, g, b) => format!("#{r:02x}{g:02x}{b:02x}"),
            _ => "#dcd7ba".into(),
        };
        let mut svg = format!(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{}\" height=\"{}\" viewBox=\"0 0 {} {}\">\n<rect width=\"100%\" height=\"100%\" rx=\"8\" fill=\"#1f1f28\"/>\n<g font-family=\"Menlo, DejaVu Sans Mono, monospace\" font-size=\"14\" xml:space=\"preserve\">\n",
            u32::from(width) * 8 + 24,
            u32::from(height) * 18 + 24,
            u32::from(width) * 8 + 24,
            u32::from(height) * 18 + 24
        );
        for y in 0..height {
            let mut x = 0;
            while x < width {
                let cell = &buffer[(x, y)];
                let mut end = x + 1;
                while end < width && buffer[(end, y)].bg == cell.bg {
                    end += 1;
                }
                svg.push_str(&format!(
                    "<rect x=\"{}\" y=\"{}\" width=\"{}\" height=\"18\" fill=\"{}\" shape-rendering=\"crispEdges\"/>\n",
                    u32::from(x) * 8 + 12,
                    u32::from(y) * 18 + 12,
                    u32::from(end - x) * 8,
                    rgb(cell.bg)
                ));
                x = end;
            }
            x = 0;
            while x < width {
                let cell = &buffer[(x, y)];
                let mut end = x + 1;
                while end < width
                    && buffer[(end, y)].fg == cell.fg
                    && buffer[(end, y)].modifier == cell.modifier
                {
                    end += 1;
                }
                let text = (x..end)
                    .map(|i| buffer[(i, y)].symbol())
                    .collect::<String>()
                    .replace('&', "&amp;")
                    .replace('<', "&lt;")
                    .replace('>', "&gt;")
                    .replace(' ', "\u{a0}");
                if !text.trim().is_empty() {
                    svg.push_str(&format!("<text x=\"{}\" y=\"{}\" fill=\"{}\" font-weight=\"{}\" textLength=\"{}\" lengthAdjust=\"spacingAndGlyphs\">{text}</text>\n",
                        u32::from(x) * 8 + 12, u32::from(y) * 18 + 26, rgb(cell.fg),
                        if cell.modifier.contains(Modifier::BOLD) { "bold" } else { "normal" }, u32::from(end - x) * 8));
                }
                x = end;
            }
        }
        svg.push_str("</g>\n</svg>\n");
        svg
    }

    #[test]
    fn rendered_snapshots() {
        let (_dir, mut disk) = disk_app();
        if let Mode::Disk(state) = &mut disk.mode {
            let tree = state.tree.as_mut().unwrap();
            for node in &mut tree.nodes {
                node.allocated = node.apparent;
                node.path =
                    PathBuf::from("/demo").join(node.path.strip_prefix(&state.root).unwrap());
            }
            tree.paths = tree
                .nodes
                .iter()
                .enumerate()
                .map(|(i, node)| (node.path.clone(), i))
                .collect();
            state.root = PathBuf::from("/demo");
        }
        disk.view = View::Disk(PathBuf::from("/demo"));
        disk.selected = None;
        disk.rebuild(true);
        snapshot(&mut disk, "disk-wide", 110, 24);
        disk.list_focus = true;
        snapshot(&mut disk, "disk-small", 32, 12);
        let (sender, mut memory) = memory_app();
        for index in 0..30 {
            let mut sample = synthetic_snapshot(&[
                (42, 100, (32 + index) * 1024),
                (43, 200, (8 + index % 4) * 1024),
            ]);
            sample.apps.extend(crate::memory::group_processes(
                vec![
                    crate::memory::Process {
                        pid: 50,
                        started: 300,
                        name: "Browser".into(),
                        executable: Some(PathBuf::from(
                            "/Applications/Browser.app/Contents/MacOS/browser",
                        )),
                        command: Some("browser".into()),
                        resident: (48 + index % 5) * 1024,
                    },
                    crate::memory::Process {
                        pid: 60,
                        started: 400,
                        name: "Terminal".into(),
                        executable: Some(PathBuf::from(
                            "/Applications/Terminal.app/Contents/MacOS/terminal",
                        )),
                        command: Some("terminal".into()),
                        resident: 12 * 1024,
                    },
                ],
                true,
            ));
            sender.send(sample).unwrap();
            memory.update();
        }
        snapshot(&mut memory, "memory-apps", 90, 24);
        memory.key(key(KeyCode::Char('v')));
        snapshot(&mut memory, "memory-system", 90, 24);
        memory.key(key(KeyCode::Char('?')));
        snapshot(&mut memory, "help", 90, 24);
    }
}
