# dotfiles

macOS development environment with Kanagawa Wave theme. Each tool can be installed and symlinked independently — no need to run the full bootstrap script.

## Prerequisites

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
- [Productivity](#productivity)
- [Audio & Visuals (Rice)](#audio--visuals-rice)
- [Browser](#browser)
- [Full Bootstrap](#full-bootstrap)

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

Prefix is `Ctrl+S`. See `~/Documents/tmux-cheatsheet.pdf` for bindings.

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

i3-like tiling. `alt-shift` (right_option) for window ops, `ctrl` for workspace switching. Workspaces auto-assign to monitors (supports 1/2/3 monitor setups). See `~/Documents/aerospace-cheatsheet.txt` for bindings.

**Post-install:** Disable macOS "Switch to Desktop N" hotkeys to free `ctrl+1-9`:

```bash
for id in $(seq 118 133) $(seq 162 177); do
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" '{ enabled = 0; }'
done
```

### Karabiner-Elements (key remapping)

```bash
brew install --cask karabiner-elements
# DO NOT overwrite existing config — Karabiner config is complex and personal
# Only symlink if setting up fresh:
# ln -sf ~/repos/dotfiles/macos/karabiner ~/.config/karabiner
```

Key mappings: `left_control` → Hyper (ctrl+alt+cmd+shift), `right_option` → alt+shift, `right_shift` → shift+ctrl, `caps_lock` → left_command.

---

## Status Bar & Borders (Rice)

### SketchyBar

```bash
brew install felixkratz/formulae/sketchybar
brew install --cask font-sf-mono-nerd-font
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
# Find your profile directory
FF_PROFILE=$(find "$HOME/Library/Application Support/Firefox/Profiles" -maxdepth 1 -name "*.default-release" | head -1)
mkdir -p "$FF_PROFILE/chrome"
cp ~/repos/dotfiles/firefox/userChrome.css "$FF_PROFILE/chrome/userChrome.css"
```

Kanagawa-themed UI: dark tab bar, dark nav bar, blue focus ring, hidden traffic lights, thin scrollbars.

**Required:** Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true` in `about:config`, then restart Firefox.

---

## Full Bootstrap

To install everything at once:

```bash
cd ~/repos/dotfiles
./bootstrap.sh
```

This installs all brew dependencies, creates symlinks, and configures everything. **Note:** Karabiner config is skipped if it already exists.

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
