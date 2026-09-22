# Hammerspoon Cheat Sheet

Hyper is `Control+Option+Command+Shift`. Holding the right Control thumb key
produces Hyper; tapping it opens the Hammerspoon command palette.

## Discovery and navigation

- `Hyper+;` — searchable command palette
- `Hyper+R` — desktop service manager
- `Hyper+W` — search all open windows by application and title
- `Hyper+Delete` or `Hyper+Forward Delete` — return to the previous window
- `Hyper+Tab` — return to the previous AeroSpace workspace
- `Cmd+Alt+C` — cycle windows of the current application

The command palette lists registered shortcuts. Desktop maintenance actions are
grouped under **Service manager**, which can be opened from the palette or
directly with `Hyper+R`.

## Desktop service manager

- Reload or restart Hammerspoon
- Reload or restart AeroSpace
- Reload or restart SketchyBar
- Refresh SketchyBar workspace indicators
- Restart JankyBorders
- Reassign AeroSpace workspaces to monitors
- Log desktop service and workspace status
- Open or clear the Hammerspoon console

## Applications

- `Hyper+G` — Google Chrome
- `Hyper+T` — Ghostty
- `Hyper+D` — Discord
- `Hyper+S` — Slack
- `Hyper+O` — Microsoft Outlook
- `Hyper+C` — Codex
- `Hyper+I` — IntelliJ IDEA
- `Hyper+F` — Firefox
- `Hyper+Z` — Zoom
- `Hyper+Q` — KeyCastr
- `Hyper+P` — Docker
- `Hyper+Space` — WezTerm scratchpad

Pressing an application shortcut again cycles that application's windows.

## Floating applications

- `Cmd+Ctrl+E` — Messages
- `Cmd+Ctrl+A` — Music
- `Cmd+Ctrl+P` — Podcasts
- `Cmd+Ctrl+W` — Notes
- `Cmd+Ctrl+T` — Telegram
- `Cmd+Ctrl+F` — Finder

## Productivity and devices

- `Hyper+M` — refresh and choose an upcoming meeting
- `Hyper+V` — Raycast clipboard history
- `Cmd+Alt+O` — audio output chooser
- `Cmd+Alt+I` — audio input chooser
- `Cmd+Alt+B` — Bluetooth device chooser
- `Cmd+Alt+W` — Wi-Fi network chooser

## Windows, spaces, and system

- `Hyper+A` — toggle fullscreen
- `Hyper+N` — create a macOS space
- `Hyper+X` — close empty macOS spaces
- ``Hyper+` `` — show the current macOS space number
- `Cmd+Alt+S` — sleep
- `Cmd+Alt+\` — open the Hammerspoon console

## Media

- `Shift+F7` — previous track
- `Shift+F8` — play or pause
- `Shift+F9` — next track

## Automatic behavior

- The display remains awake.
- Leaving the home Wi-Fi network minimizes windows and mutes the MacBook
  speakers.
- Monitor changes trigger three delayed AeroSpace stabilization passes, then a
  SketchyBar reload.
- With the built-in display connected, workspaces 1–4 remain on it and
  workspaces 5–10 are divided across external displays.
- SketchyBar highlights the visible workspace on every display.
