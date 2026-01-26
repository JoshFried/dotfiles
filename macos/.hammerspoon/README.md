# Hammerspoon Config

## Files

| File | Description |
|------|-------------|
| `init.lua` | Entry point. Keeps display awake and loads all modules. |
| `hyper.lua` | Defines hyper key (Ctrl+Alt+Cmd+Shift). |
| `launchoractivateapp.lua` | Launch or focus apps with hyper+key. Cycles windows if already focused. |
| `centeredapp.lua` | Opens apps centered at 75% width, 50% height on main screen. |
| `cycleapp.lua` | Cycles through windows of current app with highlight animation. |
| `fullscreen.lua` | Toggles fullscreen for focused window. |
| `caffeine.lua` | Triggers system sleep. |
| `hsreload.lua` | Reloads Hammerspoon config. |
| `soundswitch.lua` | Chooser for audio input/output devices. Quick-connect for AirPods. |
| `bluetooth.lua` | Chooser for paired Bluetooth devices using blueutil. |
| `wifi_watcher.lua` | Minimizes windows and mutes audio when leaving home WiFi. |
| `media.lua` | Controls Music.app playback via AppleScript. |
| `wifiswitch.lua` | Chooser for WiFi networks. Sorts known networks first, then by signal. |
| `hsconsole.lua` | Opens Hammerspoon console centered on screen. |
| `newspace.lua` | Space management: create, close empty, show current number. |
| `scratchpad.lua` | Toggle Ghostty terminal as dropdown scratchpad. |

## Dependencies

- [blueutil](https://github.com/toy/blueutil) - Required for bluetooth.lua and AirPods quick-connect

## Amethyst Integration

This config works alongside [Amethyst](https://ianyh.com/amethyst/) window manager:
- Amethyst handles window tiling (Option+Shift modifiers)
- Hammerspoon handles app launching, audio, spaces, scratchpad
- No keybinding conflicts between the two

Amethyst config is stored in `~/.amethyst.yml`. Backup/restore with:
```bash
# Backup
cp ~/.amethyst.yml ~/your-dotfiles/

# Restore
cp ~/your-dotfiles/.amethyst.yml ~/.amethyst.yml
```

## See Also

- [CHEATSHEET.md](CHEATSHEET.md) - Quick reference for all keybindings
- [~/.amethyst.yml](~/.amethyst.yml) - Amethyst tiling window manager config
