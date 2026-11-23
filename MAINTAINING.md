# Maintaining the dotfiles

## Follow an install

Start with `dotfiles.toml` to answer “who installs this file?” A symlink
resource gives both its path in the checkout and its destination on disk.
For example, `symlink.sesh-wrapper` installs `sesh/sesh-wrapper.sh` as
`~/.local/bin/dotfiles-sesh`. With a healthy link, editing the source affects
the next invocation immediately. A running shell or tmux server keeps the
configuration it already loaded.

1. `bootstrap.sh` locates the checkout and sources `macos/bootstrap.sh` on
   Darwin or `linux/bootstrap.sh` on Linux. Run the top-level script from
   either host. The platform files supply functions and depend on variables
   defined by their caller.
2. The installer prepares platform prerequisites, Homebrew and Cargo. It runs
   the Rust CLI against the manifest. Linux defaults to `core` and
   `development`. macOS also selects `desktop`. Explicit resource, profile
   or tag filters select their matching resources and dependencies.
3. The remaining bootstrap steps handle NVM, global npm packages, Go tools,
   runtime directories and tmux plugins. On older x86-64 Linux systems the
   Node installer checks glibc compatibility. The macOS finishing hook
   registers the JDK and installs the Firefox style into an existing profile.
4. On a work machine, run the private checkout's `./setup.sh --check` **after**
   installing the shared config. It lists missing or conflicting work links.
   Compare a reported destination with the proposed source and reconcile any
   local customizations. Plain `./setup.sh` installs missing links when the
   preflight finds no conflicts. `./setup.sh --replace-reviewed` backs up
   reviewed conflicts and links the managed versions.

The public CLI moves an existing destination to
`~/.local/state/dotfiles/backups/<timestamp>/` before replacing it. That
destination can be an entire directory, such as `~/.config/nvim`. The private
installer uses `${XDG_STATE_HOME:-$HOME/.local/state}/work-dotfiles/backup.*`.
Both preserve the old entry as a unit. Import any hand edits you want in the
new configuration before switching. Historical filenames outside the manifest
and private installer's target list are outside both installers' scope.

### Inspect one change

Run these from the shared checkout. `explain` gives the resource definition
and dependency relationships. `audit` inspects the live installation and
returns a nonzero status for drift. `plan` shows the proposed fix.

```sh
bin/dotfiles explain symlink.sesh-wrapper
bin/dotfiles audit symlink.sesh-wrapper
bin/dotfiles plan symlink.sesh-wrapper
```

`./bootstrap.sh --check` also checks tools handled outside the manifest. The
check writes diagnostic logs and Cargo can build the CLI. CLI logs default to
the dotfiles state directory. The bootstrap prints the actual log paths in
its summary. For an executable reported as *misplaced*, inspect its path with
`command -v` and its manifest entry. A working system binary and a missing
Homebrew formula can describe the same machine.

### Trace a CLI result in Rust

Under `dotfiles-cli/src/`, `main.rs` parses the arguments defined in `cli.rs`.
`application.rs` loads the manifest through `config.rs`, constructs the engine
and dispatches the command. The dashboard in `tui.rs` uses the same engine
as a terminal `audit`, `plan` or `apply`.

- For “why was this selected?”, start in `engine/selection.rs`. It resolves
  filters, expands `depends_on` and orders prerequisites first.
- For “why does this look unhealthy?”, follow `engine/inventory.rs` into
  `engine/audit.rs`. Inventory collects shared observations such as installed
  formula names. Audit interprets those observations for each resource.
- For “what will this write?”, read `engine/apply.rs` and `engine/mod.rs`.
  Plan includes fixable drift. Apply inspects each selected resource and
  collects per-resource results. A failed link creation attempts to restore
  the previous destination. Earlier successful changes remain applied.
- `domain.rs` holds the results rendered by `console.rs` and the dashboard.
  `tui/state.rs` manages selection and filtering, `tui/theme.rs` assigns
  styles, and `logging.rs` writes diagnostics. `system.rs` supplies external
  command execution so engine tests can substitute `engine/test_support.rs`.

## Follow a shell command

Zsh reads `~/.zshrc` at interactive startup. The shared file initializes
Homebrew, language paths and shell plugins, then sources `~/.alias.zsh` and
the optional `~/.work.zshrc`. The private loader follows its symlink back to
the work checkout, loads common work aliases, and sources the selected host's
`work.zshrc` and `work.alias.zsh`. `~/.work.secrets.zsh` is local to the host.

Put a shortcut used on both personal and work machines in `.alias.zsh`.
Put a work shortcut common to both hosts in the private `.work.alias.zsh`.
An alias with an AL2 checkout path belongs in the private `al2/work.alias.zsh`.
Shell initialization for one host belongs in its `work.zshrc`. Run `exec zsh`
to pick up a change in an existing terminal.

To diagnose a bookmark, inspect the installed link, ask a fresh interactive
shell what the name resolves to, then run the bookmark in a subshell. This
last step catches a valid alias pointing at a missing directory.

```sh
readlink ~/.work.zshrc
zsh -ic 'whence -v @odi'
zsh -ic '(@odi && pwd -P)'
```

If Powerlevel10k reports console output during initialization, read the lines
after the warning. A parse error naming `.alias.zsh` or `.zshrc` can prevent
later aliases from loading. Check the actual installed files separately with
`zsh -n ~/.zshrc` and `zsh -n ~/.alias.zsh`. For a rebase, resolve conflicts
in a separate checkout or temporary files before replacing a live symlink's
target. Open a new terminal after both files parse and run `gs` in a Git repo.

### Follow a session from the picker

Shell `sesh`, the tmux `Ctrl-e` popup and Television's `sesh` channel all call
`~/.local/bin/dotfiles-sesh`. The shared named sessions are in `sesh/sesh.toml`.
With an additive `~/.work.sesh.toml`, the wrapper concatenates the two files
and passes the completed cache file to the real `sesh` executable. If the work
file contains its own `[default_session]` or `[tui]` section, the wrapper
passes that complete file directly. Edit the source configs and let the
wrapper rebuild `${XDG_CACHE_HOME:-$HOME/.cache}/sesh/combined.toml`.

First run `~/.local/bin/dotfiles-sesh list -c` to inspect the names both
pickers receive. Then run `~/.local/bin/dotfiles-sesh preview <name>` to
exercise that entry. For Television, `television/cable/sesh.toml` controls
the list, preview, output parsing and actions. `prefix` then `T` opens it
from home because a `sesh/` directory in the current working directory can
shadow the channel name. Reload `.tmux.conf` with `prefix` then `r`.

`prefix` then `P` calls `bin/dotfiles-tmux-log-pane` and toggles the pane
marked for logs in that window. `bin/dotfiles-tmux-pane-status` receives the
pane ID, directory, PID and command from tmux and caches the rendered label.
When a pane border is empty, check the two corresponding `~/.local/bin` links.

`bin/dotfiles-copy` tries `pbcopy`, Wayland's `wl-copy`, and the X11 programs
`xclip` and `xsel` when their displays are available. In a headless tmux session
it loads a paste buffer and requests forwarding to the terminal clipboard.
Outside tmux it writes OSC 52 to the controlling terminal. To isolate
a clipboard issue, test `tmux show-buffer` after a copy. If the bytes reached
the buffer, the next component to inspect is terminal clipboard forwarding.
Neovim selects its own clipboard provider in `nvim/lua/config/options.lua`.

## Follow a Neovim feature

`nvim/init.lua` loads `config.options`, `config.patches`, `config.autocmds`
and `config.lazy` in order. The `VeryLazy` event loads `config.keymaps`,
which applies the mapping tables under `lua/config/keymaps/`. Plugin-specific
keys can also come from a plugin spec or an LSP client's buffer-local
attach callback. Use `:verbose nmap <key>` in the affected buffer to inspect
the effective mapping.

Under `nvim/lua/plugins/`, each file supplies a lazy.nvim spec or a helper
required by a spec. Subdirectory `init.lua` files gather related specs.
`extra/lang/` extends the common language tools. For example, for a Python
diagnostic, `extra/lang/python/lsp.lua` supplies Pyright and Ruff settings,
`lsp/init.lua` assembles the common setup and `lsp/servers.lua` registers
the merged settings. Formatting, linting, debugging and test discovery
have separate modules. Start with `:ConformInfo` for formatting and
`:checkhealth vim.lsp` for language servers.

The private installer adds `lua/plugins/work/scat.lua` under the **active**
Neovim config. `config/lazy.lua` imports `plugins.work` when that directory
exists. On a work machine, open a Brazil package's `Config` and run
`:set filetype?` and `:verbose nmap <leader>bl` to exercise both filetype
detection and the work plugin mapping. `nvim/lazy-lock.json` records plugin
revisions resolved by lazy.nvim.

For JVM navigation, `dotfiles_mason_registry/kotlin_lsp.lua` under `nvim/lua/`
defines the server archive and executable per platform. The shared LSP setup
registers this local Mason source first. For `jar://` navigation, inspect
`config/patches.lua` and verify `cfr-decompiler` is on `PATH`. JDTLS handles
`jdt://` and plain class files.

## Trace desktop integrations

- **macOS window management.** Karabiner's active rules live in
  `macos/karabiner/karabiner.json`. `macos/.aerospace.toml` invokes
  `aerospace-workspace-assign.sh` for monitor placement and
  `aerospace-toast.sh` for layout feedback. Hammerspoon's `init.lua`
  loads the shared hotkey registry, feature modules, optional work module,
  then the command palette. Its [module guide](macos/.hammerspoon/README.md)
  and [shortcut list](macos/.hammerspoon/CHEATSHEET.md) describe the bindings.
- **Profiles, meeting controls and displays.** `desktopprofiles.lua` maps
  applications to AeroSpace workspaces. `workspaceoverview.lua` presents
  windows on demand. `meeting_mode.lua` obtains Slack huddle state from
  `slack_huddle.lua` and reconciles mute changes through `microphone_sync.lua`.
  For a workspace appearing on the wrong monitor, follow
  `macos/sketchybar/plugins/display_ids.js` into `display_map.sh`. AppKit
  screen indexes and SketchyBar arrangement numbers can differ.
- **macOS status bar and calendar.** `macos/sketchybar/sketchybarrc`
  declares each item, event subscription and refresh interval. Follow its
  `script` setting into `plugins/` to see how the item is rendered.
  `macos/cal-events.swift` is the source for the bundled `cal-events`
  executable. The shell can refresh `/tmp/cal-events.txt`, which the
  Hammerspoon meeting chooser reads. The bootstrap copies the Firefox style
  into the profile, so a change to `firefox/userChrome.css` requires another
  copy before Firefox can pick it up.
- **Linux X11 desktop.** `linux/i3/`, `linux/picom/` and `linux/polybar/`
  contain the window manager, compositor and panel configuration. These are
  separate from the AL2 shell bootstrap. In `polybar/cuts/`, the launch and
  preview scripts replace running bars. The rofi picker scripts call other
  scripts that rewrite installed colors and restart the panel. The package
  update widget uses Arch's `checkupdates` tooling.
- **Terminal appearance and audio.** `wezterm/wezterm.lua` selects a scheme
  from `wezterm/colors/` and translates terminal shortcuts. `ghostty/config`,
  `btop/btop.conf`, `lazygit/config.yml` and `fastfetch/config.jsonc` are read
  by their respective programs. `cava/config` currently selects CoreAudio
  input and ncurses output. The `.vert` and `.frag` files in `cava/shaders/`
  are alternatives for graphical rendering.

## Standalone tools and keyboard references

`usage-tui/` builds `diskmap` and `memmap` separately from the installer.
Their entry points parse arguments under `src/bin/`. `disk.rs` streams a
filesystem scan, `memory.rs` samples processes and `history.rs` keeps recent
trends. Both feed `app.rs`, with `treemap.rs` handling tile placement and
navigation. Disk totals, memory accounting and the checks before moving an
entry to Trash are documented in the [usage guide](usage-tui/README.md).

For the Dactyl's right-hand USB setup, keep `qmk/right_usb/config.h` together
with its compilation-ready `keymap.json`. The [firmware guide](qmk/README.md)
identifies the keyboard target and build procedure. `scripts/build-cheatsheets.sh`
renders the workflow, Hammerspoon and Dactyl Markdown references into
`CHEATSHEETS.pdf`. Pass an output path to preview a documentation edit.

## Verify a change

Run from the shared checkout. The shell fixture uses a temporary home and
stub commands to exercise platform selection, launcher paths and session
composition. The Rust suite covers the engine and invokes the compiled CLI
against test fixtures.

```sh
bash tests/setup.sh
bash tests/bootstrap-linux-test.sh
cargo test --locked --all-targets --manifest-path dotfiles-cli/Cargo.toml
cargo test --locked --all-targets --manifest-path usage-tui/Cargo.toml
```

The desktop regression fixtures can also run on AL2. From the repo root, run
`bash tests/aerospace-workspace-assign-test.sh`,
`bash tests/sketchybar-spaces-test.sh`, and `lua` on each `tests/*-test.lua`
file. They simulate monitor transitions, app windows and meeting controls.
Use a real Mac for Accessibility permission prompts and physical device changes.

Use the live checks in the relevant section for behavior that needs a real
checkout, an interactive terminal or a desktop service. The CI workflow runs
the shell fixture and Rust formatting, lint and test checks on macOS and
Ubuntu.
