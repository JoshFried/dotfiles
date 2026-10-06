# Keyboard Development Workflow Cheat Sheet

This is the public, machine-independent quick reference for the tracked
AeroSpace, tmux, sesh, shell, and clipboard configuration. Machine-specific
work aliases and sessions remain in private files.

## Core Modifiers

- `Hyper`: Control+Option+Shift+Command.
- Hold `Right Control` or `Caps Lock` for Hyper.
- Tap `Right Control` or `Caps Lock` for the Hammerspoon command palette.
- `Right Option`: Option+Shift, used for AeroSpace operations.
- tmux prefix: `Ctrl+S`.

## AeroSpace

### Focus and Move

- `Option+Shift+H/J/K/L`: focus left/down/up/right.
- `Option+Shift+Control+H/J/K/L`: move the focused window.
- `Control+Shift+H/J/K/L`: join the window with its neighbor.
- `Control+Shift+P/N`: focus the previous/next monitor.
- `Option+Shift+N`: move the window to the next monitor and follow it.

### Workspaces

- `Control+1..9/0`: switch to workspace 1..9/10.
- `Option+Shift+1..9/0`: move the window to workspace 1..9/10 and follow it.
- `Hyper+Tab`: switch back to the previous workspace.

### Layout

- `Option+Shift+-/=`: shrink/grow the focused tile.
- `Control+Shift+R`: enter resize mode.
- Resize mode `H/J/K/L`: change width/height.
- Resize mode `Enter` or `Esc`: return to normal mode.
- `Option+Shift+T`: toggle floating/tiling.
- `Option+Shift+F`: toggle fullscreen.
- `Option+Shift+B`: balance window sizes.
- `Control+Shift+F`: flatten the current workspace layout.
- `Control+Shift+Backspace`: reload AeroSpace.

## tmux

### Sessions and Windows

- `Prefix+C-e`: sesh/fzf session picker.
- `Prefix+T`: Television session picker.
- `Prefix+N`: create a named session.
- `Prefix+D`: choose and kill a session with confirmation.
- `Prefix+c`: create a window in the current pane directory.
- `Prefix+n/p`: next/previous window.
- `Prefix+Ctrl+N/Ctrl+P`: next/previous window.
- `Prefix+Ctrl+H/Ctrl+L`: previous/next window.
- `Prefix+Tab`: return to the last window.
- `Prefix+X`: choose a window to kill.

### Panes and Popups

- `Prefix+|`: split horizontally in the current directory.
- `Prefix+-`: split vertically in the current directory.
- `Prefix+H/J/K/L`: resize by five cells.
- `Prefix+Option+H/J/K/L`: repeatable resize by five cells.
- `Ctrl+H/J/K/L`: move between Neovim splits and tmux panes.
- `Prefix+=`: evenly balance the current layout.
- `Prefix+g`: open lazygit in a popup.
- `Prefix+P`: toggle a lower log shell in the current window.
- `Prefix+o`: open a command in a new window.

Pane borders show local/dev context, Git branch, package name, devcontainer
presence, and up to three listening ports.

### Copy and Links

- `Prefix+Space`: tmux-thumbs; choose a highlighted token to copy it.
- tmux-thumbs writes to the tmux buffer and emits OSC52 for the local terminal
  clipboard, including supported remote terminal sessions.
- `Prefix+u`: find URLs; `Ctrl+Y` copies the selected URL from its picker.
- `Prefix+[`: enter copy mode; `v` starts selection and `y` copies.
- `Prefix+r`: reload `.tmux.conf`.

## sesh

- `Alt+S`: fuzzy session picker from any Zsh prompt.
- `sesh connect NAME`: create or attach to a named session.
- Inside the tmux picker:
  - `Ctrl+A`: all sources.
  - `Ctrl+T`: tmux sessions.
  - `Ctrl+G`: configured sessions.
  - `Ctrl+X`: zoxide directories.
  - `Ctrl+F`: directory search.
  - `Ctrl+D`: kill the selected session.
- `@dotfiles` and `@nvim-config`: connect through sesh inside tmux; otherwise
  change directly to the project directory.

## Shell

- `sz`: replace the current shell with a freshly loaded Zsh.
- `ez`, `ea`, `ew`, `el`: edit Zsh, public aliases, private work aliases, or
  local shell configuration.
- `eh`, `ek`, `eg`: edit Hammerspoon, Karabiner, or Ghostty configuration.
- `z NAME`: jump to a frequently used directory through zoxide.
- `v`, `lg`, `g`: Neovim, lazygit, and Git.
- `copy FILE`: copy a file through the cross-host clipboard helper.

## SketchyBar

- Click CPU for memory, load average, and disk usage.
- Click Wi-Fi for interface, local IP, download rate, and upload rate.
- Click battery for power source, remaining time, health, and cycle count.
- Click the clock for upcoming meetings and Calendar actions.
- Click the microphone to toggle system-wide input mute and sync an active Zoom meeting.
- Click the Zoom camera control to toggle video. Green is on, red `Off` is off,
  and purple means no active Zoom meeting.
- Right-click CPU, Wi-Fi, battery, or clock for the original direct system action.
