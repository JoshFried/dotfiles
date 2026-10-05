# Hammerspoon Desktop Cheat Sheet

Hyper is Control+Option+Command+Shift. Hold `Right Control` or `Caps Lock` for
Hyper; tap either key to open the command palette.

## Discovery

- `Hyper+;`: searchable command palette.
- `Hyper+/`: context-aware searchable workflow cheatsheet.
- `Hyper+R`: desktop service manager.
- `Hyper+W`: search open windows by application and title.
- `Hyper+Delete` or `Hyper+Forward Delete`: return to the previous window.
- `Hyper+Tab`: return to the previous AeroSpace workspace.
- `Cmd+Option+C`: cycle windows for the focused application.

The command palette is generated from the live Hammerspoon binding registry.

## Applications

- `Hyper+G`: Google Chrome.
- `Hyper+T`: Ghostty.
- `Hyper+D`: Discord.
- `Hyper+S`: Slack.
- `Hyper+O`: Microsoft Outlook.
- `Hyper+C`: Codex.
- `Hyper+I`: IntelliJ IDEA.
- `Hyper+F`: Firefox.
- `Hyper+Z`: Zoom.
- `Hyper+Q`: KeyCastr.
- `Hyper+P`: Docker.
- `Hyper+Space`: WezTerm scratchpad.

Pressing the shortcut for an already focused application cycles its windows.

## Floating Applications

- `Cmd+Control+E`: Messages.
- `Cmd+Control+A`: Music.
- `Cmd+Control+P`: Podcasts.
- `Cmd+Control+W`: Notes.
- `Cmd+Control+T`: Telegram.
- `Cmd+Control+F`: Finder.

## Productivity and Devices

- `Hyper+M`: refresh and choose an upcoming meeting.
- `Hyper+Shift+M`: toggle system and Zoom microphone mute together.
- `Hyper+Shift+C`: toggle the Zoom camera.
- `Hyper+V`: Raycast clipboard history.
- `Cmd+Option+O`: audio output chooser.
- `Cmd+Option+I`: audio input chooser.
- `Cmd+Option+B`: paired Bluetooth device chooser.
- `Cmd+Option+W`: Wi-Fi network chooser.

The Bluetooth chooser prioritizes connected devices. Selecting a disconnected
device connects it; selecting a connected device disconnects it. Battery levels
are shown when macOS exposes them.

## Windows and Spaces

- `Hyper+A`: toggle native fullscreen.
- `Hyper+N`: create a macOS space.
- `Hyper+X`: close empty macOS spaces.
- ``Hyper+` ``: show the current macOS space number.
- `Cmd+Option+S`: sleep.
- `Cmd+Option+\`: open the Hammerspoon console.

## Media

- `Shift+F7`: previous track.
- `Shift+F8`: play or pause.
- `Shift+F9`: next track.

Unmodified `F7/F8/F9` are mapped by Karabiner to the equivalent system media
keys.

## Service Manager

`Hyper+R` provides:

- Reload Hammerspoon configuration or restart Hammerspoon.
- Reload AeroSpace configuration or restart AeroSpace.
- Reload SketchyBar or restart its Homebrew service.
- Refresh SketchyBar workspace indicators.
- Restart JankyBorders.
- Reassign AeroSpace workspaces to monitors.
- Log Homebrew, AeroSpace, and SketchyBar status.
- Open or clear the Hammerspoon console.

## Battery Alerts

- Alerts fire once per discharge cycle at 20%, 15%, 10%, and 5%.
- The 10% and 5% alerts are marked critical.
- Each threshold shows a centered alert and a persistent macOS notification.
- Plugging into AC power resets the threshold history.

## Automatic Behavior

- The display remains awake.
- Leaving the home Wi-Fi network minimizes windows and mutes MacBook speakers.
- Monitor changes trigger three delayed AeroSpace stabilization passes, then a
  SketchyBar reload.
- With the built-in display connected, workspaces 1-4 remain on it and
  workspaces 5-10 are distributed across external displays.
- SketchyBar highlights the visible workspace on each display.
