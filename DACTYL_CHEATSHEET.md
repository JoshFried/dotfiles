# Dactyl Manuform 5x7 — Keybinding Cheatsheet

> What each key does after QMK + Karabiner processing.
> Empty cells on layers 1-3 = transparent (same as Layer 0).

---

## Layer 0 — Base

```
LEFT HAND                                                          RIGHT HAND

┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐  ┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐
│  Esc  │   1   │   2   │   3   │   4   │   5   │   6   │  │   7   │   8   │   9   │   0   │   -   │   =   │       │
├───────┼───────┼───────┼───────┼───────┼───────┼───────┤  ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
│  Tab  │   Q   │   W   │   E   │   R   │   T   │ Home  │  │   `   │  End  │   Y   │   U   │   I   │   O   │   P   │
├───────┼───────┼───────┼───────┼───────┼───────┼───────┤  ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
│ CTRL  │   A   │   S   │   D   │   F   │   G   │Ct+S+Tb│  │ Ct+Tb │   H   │   J   │   K   │   L   │   ;   │   '   │
├───────┼───────┼───────┼───────┼───────┼───────┴───────┘  └───────┴───────┼───────┼───────┼───────┼───────┼───────┤
│ SHIFT │   Z   │   X   │   C   │   V   │   B   │                  │   N   │   M   │   ,   │   .   │   /   │ S+CTL │
├───────┼───────┼───────┼───────┼───────┴───────┘                  └───────┼───────┼───────┼───────┼───────┼───────┤
│ `/Ly2 │  Ly1  │   (   │   )   │                                          │   -   │   =   │   +   │  Ly3  │       │
└───────┴───────┴───────┴───────┘                                          └───────┴───────┴───────┴───────┴───────┘

              THUMBS LEFT                                                        THUMBS RIGHT
        ┌──────────┬──────────┐                                            ┌──────────┬──────────┐
        │  PgUp    │    [     │                                            │    ]     │  PgDn    │
        │  /Ly1    │          │                                            │          │  /Ly3    │
        ├──────────┼──────────┤                                            ├──────────┼──────────┤
        │   CTRL   │  SPACE   │                                            │  ENTER   │  BKSP    │
        ├──────────┼──────────┤                                            ├──────────┼──────────┤
        │   ALT    │  HYPER   │                                            │  HYPER   │  OPT+SH  │
        └──────────┴──────────┘                                            └──────────┴──────────┘
```

### Legend

```
CTRL    = Control (QMK sends Left GUI, Karabiner remaps to Ctrl)
S+CTL   = Shift+Control (QMK sends Right Shift, Karabiner remaps)
HYPER   = All four modifiers held at once: Ctrl+Opt+Shift+Cmd
OPT+SH  = Option+Shift (QMK sends Right Alt, Karabiner remaps)
/Ly1    = hold for Layer 1, tap for the printed key
/Ly2    = hold for Layer 2, tap for `
/Ly3    = hold for Layer 3, tap for the printed key
Ct+S+Tb = Ctrl+Shift+Tab (previous tab)
Ct+Tb   = Ctrl+Tab (next tab)
```

---

## Layer 1 — Function Keys & Navigation (hold Ly1)

Only changed keys shown. Everything else = Layer 0.

```
LEFT HAND                                                          RIGHT HAND

┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐  ┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐
│       │  F1   │  F2   │  F3   │  F4   │  F5   │  F6   │  │  F7   │  F8   │  F9   │  F10  │  F11  │  F12  │       │
├───────┼───────┼───────┼───────┼───────┼───────┼───────┤  ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
│       │       │       │  Up   │       │       │       │  │       │       │       │       │       │       │       │
├───────┼───────┼───────┼───────┼───────┼───────┼───────┤  ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
│       │       │ Left  │ Down  │ Right │       │ BOOT! │  │       │       │       │       │       │       │       │
├───────┼───────┼───────┼───────┼───────┴───────┘          └───────┴───────┼───────┼───────┼───────┼───────┼───────┤
│       │       │       │       │                                          │       │       │       │       │       │
├───────┼───────┼───────┼───────┘                                          └───────┼───────┼───────┼───────┼───────┤
│       │ (hold)│ Prev  │ Next  │                                                  │       │       │       │       │
└───────┴───────┴───────┴───────┘                                                  └───────┴───────┴───────┴───────┘

              THUMBS LEFT                                                        THUMBS RIGHT
        ┌──────────┬──────────┐                                            ┌──────────┬──────────┐
        │          │          │                                            │          │          │
        ├──────────┼──────────┤                                            ├──────────┼──────────┤
        │          │          │                                            │   DEL    │          │
        ├──────────┼──────────┤                                            ├──────────┼──────────┤
        │          │          │                                            │          │          │
        └──────────┴──────────┘                                            └──────────┴──────────┘
```

`(hold)` = this is the Ly1 hold key itself
`BOOT!` = enters QMK bootloader for flashing — careful!

---

## Layer 2 — Numpad (hold `/Ly2)

Only right hand changes. Left hand = Layer 0.

```
                                                           RIGHT HAND

                                                    ┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐
                                                    │       │       │ NumLk │       │   -   │   +   │       │
                                                    ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
                                                    │       │       │   7   │   8   │   9   │       │       │
                                                    ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
                                                    │       │       │   4   │   5   │   6   │   *   │       │
                                                    ├───────┴───────┼───────┼───────┼───────┼───────┼───────┤
                                                    │               │   1   │   2   │   3   │   /   │       │
                                                    │               ├───────┼───────┼───────┼───────┼───────┤
                                                    │               │   0   │   .   │       │       │       │
                                                    └───────────────┴───────┴───────┴───────┴───────┴───────┘

                                                                         THUMBS RIGHT
                                                                   ┌──────────┬──────────┐
                                                                   │          │          │
                                                                   ├──────────┼──────────┤
                                                                   │ NumEnter │          │
                                                                   ├──────────┼──────────┤
                                                                   │          │          │
                                                                   └──────────┴──────────┘
```

---

## Layer 3 — Media & Arrows (hold Ly3)

Only changed keys shown.

```
LEFT HAND                                                          RIGHT HAND

┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐  ┌───────┬───────┬───────┬───────┬───────┬───────┬───────┐
│       │       │       │       │       │       │       │  │       │       │       │       │       │       │       │
├───────┼───────┼───────┼───────┼───────┼───────┼───────┤  ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
│  Esc  │   1   │   2   │   3   │   4   │   5   │   6   │  │       │   7   │   8   │   9   │   0   │   -   │   =   │
├───────┼───────┼───────┼───────┼───────┼───────┼───────┤  ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
│       │ Vol-  │ Vol+  │ Mute  │       │       │       │  │       │       │       │       │       │  Up   │       │
├───────┼───────┼───────┼───────┼───────┴───────┘          └───────┴───────┼───────┼───────┼───────┼───────┼───────┤
│       │       │       │       │                                          │       │ Left  │ Down  │ Right │       │
└───────┴───────┴───────┴───────┘                                          └───────┴───────┴───────┴───────┴───────┘
```

---

## Karabiner Global Shortcuts

| Combo              | Action                              |
|--------------------|-------------------------------------|
| Cmd + H/J/K/L      | Arrow keys (vim-style navigation)   |
| Cmd+Q twice         | Quit app (single press is blocked)  |
| Cmd+H              | Disabled (prevents accidental hide) |
| F7 / F8 / F9       | Rewind / Play-Pause / Fast Forward  |

---

## Flashing Firmware

```bash
qmk compile ~/repos/dotfiles/keymaps.json
qmk flash ~/repos/dotfiles/keymaps.json     # flash LEFT half (USB side)
# unplug TRRS, move USB to right half
qmk flash ~/repos/dotfiles/keymaps.json     # flash RIGHT half
```

Trigger bootloader: hold Ly1 + press BOOT key, or short RST to GND on Pro Micro.
Flash BOTH halves — each has its own Pro Micro with separate firmware.

---

## Known Issue: Hyper Key Registers as Command

The Dactyl needs a dedicated device entry in Karabiner with
vendor_id 17485 / product_id 13623. Without it, the catch-all
device rule remaps CapsLock to Command before the Hyper complex
modification can intercept it. Also ensure you flash BOTH halves.
