# dotfiles

Shared macOS and Linux development environment with a Kanagawa Wave theme. Each tool can be installed and symlinked independently — no need to run the full bootstrap script.

For the install sequence, shell load order, source layout and checks to run after
an edit, see the [maintainer guide](MAINTAINING.md).

## Prerequisites

For a full install on macOS or Amazon Linux 2, run `./bootstrap.sh` from the checkout. The individual Homebrew examples below target macOS.

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set XDG config home (add to .zshrc if not present)
export XDG_CONFIG_HOME="$HOME/.config"
```

## Table of Contents

- [Shell](#shell)
- [Coding](#coding)
- [Terminal](#terminal)
- [Window Management (Rice)](#window-management-rice)
- [Status Bar & Borders (Rice)](#status-bar--borders-rice)
- [Automation](#automation)
- [Session Management](#session-management)
- [Productivity](#productivity)
- [Audio & Visuals (Rice)](#audio--visuals-rice)
- [Browser](#browser)
- [Dotfiles TUI](#dotfiles-tui)
- [Disk and Memory Treemaps](#disk-and-memory-treemaps)
- [Keyboard Firmware](#keyboard-firmware)
- [Full Bootstrap](#full-bootstrap)
- [After Bootstrap](#after-bootstrap)

---

## Shell

### Zsh

```bash
ln -sf ~/repos/dotfiles/.zshrc ~/.zshrc
```

### tmux

```bash
ln -sf ~/repos/dotfiles/.tmux.conf ~/.tmux.conf
```

Prefix is `Ctrl+S`. See [`WORKFLOW_CHEATSHEET.md`](WORKFLOW_CHEATSHEET.md) for
tmux, sesh, AeroSpace, and shell bindings.

---

## Coding

### Neovim

```bash
brew install neovim
ln -sf ~/repos/dotfiles/nvim ~/.config/nvim
```

LazyVim-based config with LSP, Treesitter, and Kanagawa theme.

### lazygit

```bash
brew install lazygit jesseduffield/lazygit/lazygit
ln -sf ~/repos/dotfiles/lazygit ~/.config/lazygit
```

Kanagawa theme, delta pager, nerd font icons, nvim as editor.

### git-delta

```bash
brew install git-delta
```

Configured globally via `.gitconfig` — line numbers, navigate mode, dark syntax theme. No symlink needed; settings live in your gitconfig.

---

## Terminal

### Ghostty (primary)

```bash
brew install --cask ghostty
ln -sf ~/repos/dotfiles/ghostty ~/.config/ghostty
```

Kanagawa Wave theme, 0.9 opacity, blur 20, no decorations.

### WezTerm (scratchpad / floating)

```bash
brew install --cask wezterm
ln -sf ~/repos/dotfiles/wezterm ~/.config/wezterm
```

Used as a floating scratchpad terminal via Hammerspoon (`Hyper+Space`).

---

## Window Management (Rice)

### AeroSpace (tiling WM)

```bash
brew install --cask nikitabobko/tap/aerospace
ln -sf ~/repos/dotfiles/macos/.aerospace.toml ~/.aerospace.toml
ln -sf ~/repos/dotfiles/macos/aerospace-workspace-assign.sh ~/.config/aerospace-workspace-assign.sh
ln -sf ~/repos/dotfiles/macos/aerospace-toast.sh ~/.config/aerospace-toast.sh
chmod +x ~/repos/dotfiles/macos/aerospace-workspace-assign.sh
chmod +x ~/repos/dotfiles/macos/aerospace-toast.sh
```

i3-like tiling. `alt-shift` (right_option) handles window operations and
`ctrl` switches workspaces. Workspaces auto-assign to monitors for one-, two-,
and three-monitor setups. See
[`WORKFLOW_CHEATSHEET.md`](WORKFLOW_CHEATSHEET.md) for bindings.

**Post-install:** Disable macOS "Switch to Desktop N" hotkeys to free `ctrl+1-9`:

```bash
for id in $(seq 118 133) $(seq 162 177); do
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" '{ enabled = 0; }'
done
```

### Karabiner-Elements (key remapping)

```bash
brew install --cask karabiner-elements
mkdir -p ~/.config/karabiner
ln -sf ~/repos/dotfiles/macos/karabiner/karabiner.json \
    ~/.config/karabiner/karabiner.json
```

Only the active `karabiner.json` is managed. Imported complex-modification
assets and Karabiner's generated backups remain local. The bootstrap and CLI
back up an existing active configuration before linking the checked-in file.

Hyper is implemented in two stages: the global complex rule maps logical
`right_control` to ctrl+alt+cmd+shift, while configured Apple laptop keyboards
map their physical `left_control` and `right_command` into that path. On those
keyboards, physical `caps_lock` becomes Command and physical `left_command`
becomes Control. Other mappings include `right_option` → alt+shift and
`right_shift` → shift+ctrl. Cmd+H/J/K/L navigation remains active in Raycast;
Cmd+Shift+K opens Raycast's native Action Panel.

---

## Status Bar & Borders (Rice)

### SketchyBar

```bash
brew install felixkratz/formulae/sketchybar
brew install --cask font-sf-mono-nerd-font-ligaturized
brew install jq
brew tap kvndrsslr/tap && brew install sketchybar-app-font
ln -sf ~/repos/dotfiles/macos/sketchybar ~/.config/sketchybar
chmod +x ~/.config/sketchybar/plugins/*.sh
brew services start felixkratz/formulae/sketchybar
```

Kanagawa-themed bar with AeroSpace workspace integration, app icons, media widget, battery, wifi, cpu, clock.

### JankyBorders

```bash
brew install felixkratz/formulae/borders
ln -sf ~/repos/dotfiles/macos/borders ~/.config/borders
brew services start felixkratz/formulae/borders
```

Active border: dark green (`#5f7a56`), inactive: `#363646`, width 9.

---

## Automation

### Hammerspoon

```bash
brew install --cask hammerspoon
ln -sf ~/repos/dotfiles/macos/.hammerspoon ~/.hammerspoon
```

Provides: app launchers (`Hyper+key`), centered floating apps (`Cmd+Ctrl+key`), WezTerm scratchpad (`Hyper+Space`), fullscreen toggle (`Hyper+A`), AeroSpace workspace back-and-forth (`Hyper+Tab`), media keys, WiFi watcher, caffeinate, and more.

**Required:** Enable `hs.ipc` for CLI integration (already in init.lua). Grant Accessibility permissions in System Settings.

See
[`macos/.hammerspoon/CHEATSHEET.md`](macos/.hammerspoon/CHEATSHEET.md) for the
complete desktop reference. Run `scripts/build-cheatsheets.sh` to regenerate
the combined printable [`CHEATSHEETS.pdf`](CHEATSHEETS.pdf).

---

## Session Management

### zoxide

```bash
brew install zoxide
```

Smarter `cd` that tracks most-used directories. Initialized in `.zshrc` via `eval "$(zoxide init zsh)"`. Powers sesh's directory history. Use `z <partial-name>` to jump.

### sesh

```bash
brew install sesh
mkdir -p ~/.config/sesh
ln -sf ~/repos/dotfiles/sesh/sesh.toml ~/.config/sesh/sesh.toml
```

Smart tmux session manager. Combines tmux sessions + zoxide dirs + named projects in one picker. `sesh connect <name>` creates-or-attaches to a named session with the configured startup command.

**Config files:**

- `sesh/sesh.toml` — personal, checked in (symlinked to `~/.config/sesh/sesh.toml`). Defines the `dotfiles`, `nvim-config`, `tmux-config`, `tmp`, `downloads` sessions and a `~/repos/*` wildcard that auto-opens nvim.
- `~/.work.sesh.toml` adds this host’s work sessions. Shell, tmux, and Television use the installed `dotfiles-sesh` launcher. Older complete work configs containing `[default_session]` or `[tui]` still load independently. When migrating a full config, retain its unique sessions and reconcile any customized defaults before switching to an additive file.

**Tmux bindings** (prefix `Ctrl-S`):

- `prefix + C-e` — sesh fzf popup with source-cycling (`Ctrl-a` all, `Ctrl-t` tmux, `Ctrl-g` configs, `Ctrl-x` zoxide, `Ctrl-f` find dirs, `Ctrl-d` kill session)
- `prefix + T` — television sesh picker (`Enter` connects, `Ctrl-d` kills)

**Zsh binding:** `Alt-s` opens a fuzzy session picker at any shell prompt (works in and out of tmux).

`@dotfiles` and `@nvim-config` call `_sesh_or_cd` in `.alias.zsh`. Inside tmux they connect to a named session. Outside tmux they change directory. The private checkout defines work bookmarks for each host. On AL2 those directory aliases use `cd` and require the corresponding checkout to exist.

### television

```bash
brew install television
```

Fast Rust-based fuzzy finder with pluggable "channels" (files, git, env, sesh, custom). Used in tmux via `prefix + T` for session picking. Not a Telescope replacement — keep using Telescope inside nvim.

---

## Productivity

### btop

```bash
brew install btop
ln -sf ~/repos/dotfiles/btop ~/.config/btop
```

Kanagawa theme, vim keys, transparent background.

### fastfetch

```bash
brew install fastfetch
ln -sf ~/repos/dotfiles/fastfetch ~/.config/fastfetch
```

System info with Apple logo. Replaces neofetch.

---

## Audio & Visuals (Rice)

### cava (audio visualizer)

**Must be built from source** for CoreAudio tap support (system audio capture without loopback):

```bash
brew install fftw libtool automake pkgconf iniparser ncurses
cd /tmp && git clone https://github.com/karlstav/cava.git && cd cava
export PATH="/opt/homebrew/opt/libtool/libexec/gnubin:$PATH"
export LDFLAGS="-L/opt/homebrew/lib -L/opt/homebrew/opt/ncurses/lib"
export CPPFLAGS="-I/opt/homebrew/include -I/opt/homebrew/opt/ncurses/include"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/ncurses/lib/pkgconfig"
./autogen.sh && ./configure && make -j$(sysctl -n hw.ncpu) && sudo make install
```

```bash
ln -sf ~/repos/dotfiles/cava ~/.config/cava
```

Uses CoreAudio tap for system audio (macOS 14.2+). Grant "Screen & System Audio Recording" permission to your terminal app.

### nowplaying-cli

```bash
brew install nowplaying-cli
```

Used by SketchyBar media widget. No config needed.

---

## Browser

### Firefox

```bash
brew install --cask firefox

# Find your profile directory
FF_PROFILE=$(find "$HOME/Library/Application Support/Firefox/Profiles" -maxdepth 1 -name "*.default-release" | head -1)
mkdir -p "$FF_PROFILE/chrome"
cp ~/repos/dotfiles/firefox/userChrome.css "$FF_PROFILE/chrome/userChrome.css"
```

Kanagawa-themed UI: dark tab bar, dark nav bar, blue focus ring, hidden traffic lights, thin scrollbars.

**Required:** Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true` in `about:config`, then restart Firefox.

---

## Dotfiles TUI

The Rust CLI audits the machine against `dotfiles.toml` and opens an interactive
dashboard by default:

```bash
./bin/dotfiles
```

Use `j`/`k` to navigate, `/` to filter, `space` to select changes, `enter` to
apply, `r` to refresh the audit, and `i` to include healthy resources.

Color carries the same meaning in the CLI and TUI: green is healthy or
successful, yellow is missing or planned, violet is misplaced, red is drifted,
blocked, or failed, and blue identifies resources and controls. Colors are
disabled automatically for redirected output and by `NO_COLOR`; JSON output is
always uncolored.

The same engine supports non-interactive workflows:

```bash
dotfiles audit
dotfiles audit --profile desktop --json
dotfiles plan symlink.hammerspoon
dotfiles plan --profile desktop
dotfiles apply --profile desktop
dotfiles explain symlink.hammerspoon
```

Resources, profiles, tags, dependencies, desired paths, and package identifiers
are declared in `dotfiles.toml`. Applying a symlink first moves an existing
destination into `~/.local/state/dotfiles/backups`. Formula resources can
declare an executable override or fallback file paths so tools installed by
another package manager are reported as misplaced or drifted instead of
missing. This manifest opts into installing the Homebrew formula when an executable comes from another installer. The CLI leaves that existing executable in place. Formulae otherwise probe a same-named executable on `PATH`,
`~/.local/bin`, `~/.cargo/bin`, `~/go/bin`, `~/bin`, and common system
prefixes.

### Package Version Policy

Homebrew packages use a floating compatibility-line policy. The manifest names
the supported line, while Homebrew selects and updates the concrete release:

- Unversioned formulae such as `ripgrep` follow Homebrew's current stable release.
- Major-version formulae such as `python@3` follow Homebrew's current Python 3
  alias, even when the installed canonical formula is named `python@3.14`.
- Fixed compatibility lines such as `openjdk@21` remain on that major line while
  Homebrew supplies compatible patch and minor updates.

The machine configuration intentionally does not pin exact language patch
versions. Projects that require reproducibility should declare their own
runtime version and isolated environment, such as `.python-version`, a virtual
environment, or the project's package and lock files. Upgrading the global
Homebrew runtime must not be treated as upgrading every project's environment.

Every run writes structured trace-level JSON logs under
`~/.local/state/dotfiles/logs`. Use `-v`, `-vv`, or `-vvv` for progressively
more terminal detail, or `--log-directory PATH` to redirect persistent logs.
TUI sessions remain file-only so diagnostic output cannot corrupt the screen.

## Disk and Memory Treemaps

Install the standalone Kanagawa disk and memory tools:

```bash
cargo install --path usage-tui --locked
diskmap ~/Downloads
memmap --view apps
```

Use Vim movement keys, Enter to drill down, Tab for the list, and `?` for help.
See [usage-tui](usage-tui/README.md) for controls, accounting limitations, and
Move to Trash behavior.

## Keyboard Firmware

The Dactyl Manuform 5x7 configuration lives in [qmk](qmk/README.md).
It includes the keymap and `MASTER_RIGHT` override for USB connected to
the right half, with instructions for building locally and flashing
through QMK Toolbox.

## Full Bootstrap

Run `./bootstrap.sh --check` to audit, then `./bootstrap.sh` to install. The installer and `dotfiles` CLI use `core` and `development` on Linux and add `desktop` on macOS. Use explicit `--profile` flags for a different selection.

Existing Linux installs can continue using `./bootstrap-linux.sh`. It forwards to the shared installer. If you copied the launcher outside the checkout, pass `--repo ~/repos/dotfiles` or set `DOTFILES_REPO`.

The installer uses Homebrew on both hosts. Linux bootstraps missing build prerequisites through the system package manager and selects a compatible Node build on older x86_64 glibc systems. macOS registers OpenJDK and installs the Firefox style when a profile exists. The CLI backs up replaced links and files under `~/.local/state/dotfiles/backups`. Bootstrap logs are in `${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/`.

Both hosts install `~/.local/bin/dotfiles-copy`, `~/.local/bin/dotfiles-sesh`, and the Television sesh channel. On a remote terminal, clipboard forwarding requires the connecting terminal to allow OSC 52 writes.

## After Bootstrap

After a successful run on macOS:

1. Open a new terminal or run `exec zsh`. Run `p10k configure` if the prompt has
   not been configured on this machine.
2. Open Neovim. Lazy.nvim installs plugins on first launch; run `:Mason` to
   confirm the required language servers are present.
3. Start the background services:

   ```bash
   brew services start sketchybar
   brew services start borders
   ```

4. Open Hammerspoon and AeroSpace, then grant each application
   Accessibility access under **System Settings → Privacy & Security →
   Accessibility**. Hammerspoon's `hs` command is enabled by the checked-in
   configuration.
5. Open Karabiner-Elements and confirm the checked-in profile is active. Add the
   Dactyl keyboard if needed using vendor ID `17485` and product ID `13623`.
   Complete any DriverKit, system extension, and Input Monitoring prompts shown
   by macOS.
6. Disable the macOS **Switch to Desktop N** keyboard shortcuts described in
   [AeroSpace](#aerospace-tiling-wm) so `ctrl+1-9` can select workspaces.
7. Open Firefox once to create its profile, re-run `./bootstrap.sh`, then set
   `toolkit.legacyUserProfileCustomizations.stylesheets` to `true` in
   `about:config` and restart Firefox.
8. On a work host, follow the private checkout’s migration instructions to install the optional work shell, editor plugins, and session list.

---

## Kanagawa Wave Palette

| Color       | Hex       | Usage                    |
|-------------|-----------|--------------------------|
| sumiInk3    | `#1F1F28` | Background               |
| sumiInk0    | `#16161D` | Deep background          |
| sumiInk4    | `#2A2A37` | Light background         |
| sumiInk5    | `#363646` | Lighter bg / borders     |
| fujiWhite   | `#DCD7BA` | Foreground               |
| oldWhite    | `#C8C093` | Dim foreground           |
| crystalBlue | `#7E9CD8` | Accent / active          |
| springGreen | `#98BB6C` | Green                    |
| waveRed     | `#E46876` | Red / errors             |
| carpYellow  | `#E6C384` | Yellow / warnings        |
| oniViolet   | `#957FB8` | Violet                   |
| surimiOrange| `#FFA066` | Orange                   |
| katanaGray  | `#727169` | Comments / inactive      |
