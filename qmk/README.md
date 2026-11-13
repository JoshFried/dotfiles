# Dactyl Manuform firmware

The `right_usb` keymap targets `handwired/dactyl_manuform/5x7` with
`LAYOUT_5x7`. Connect USB to the physical right half.

[`right_usb/config.h`](right_usb/config.h) sets `MASTER_RIGHT` so the USB
half uses the right-hand keys. This preserves the setup used when the left
half's USB connection stopped working.

[`right_usb/keymap.json`](right_usb/keymap.json) is the compilation-ready
version of the original [QMK Configurator export](../keymaps.json). Empty
layers 4–9 contain 74 `KC_NO` entries each; all populated layers, including
layer 10, retain their original bindings and indexes.

The successful build used QMK revision
`33292390974c75362ca30873c482d052e0bd7a63` on November 13, 2026. The target
uses an ATmega32U4 with the Caterina bootloader.

## Build

With QMK and its AVR toolchain installed, run these commands from the
dotfiles repository. Adjust `QMK_CHECKOUT` if the firmware checkout lives
elsewhere.

```bash
DOTFILES_QMK_SOURCE="$PWD/qmk/right_usb"
QMK_CHECKOUT="$HOME/qmk_firmware"
QMK_KEYMAP_DIR="$QMK_CHECKOUT/keyboards/handwired/dactyl_manuform/5x7/keymaps/right_usb"

mkdir -p "$QMK_KEYMAP_DIR"
cp "$DOTFILES_QMK_SOURCE/config.h" "$DOTFILES_QMK_SOURCE/keymap.json" "$QMK_KEYMAP_DIR/"
cd "$QMK_CHECKOUT"
qmk compile -kb handwired/dactyl_manuform/5x7 -km right_usb
```

The output is `handwired_dactyl_manuform_5x7_right_usb.hex` in the QMK
checkout. On this machine, its full path is:

```text
/Users/joshfri/qmk_firmware/handwired_dactyl_manuform_5x7_right_usb.hex
```

## Flash

Open the generated `.hex` in QMK Toolbox and select `ATmega32U4`.
Connect USB to the right half, enter the bootloader using the keyboard's
reset button or the currently installed firmware's `QK_BOOT` binding,
then click **Flash** when Toolbox detects the bootloader.

The keys needed to enter the bootloader depend on the firmware currently
running on the keyboard. A new keymap's reset binding becomes available
after flashing that keymap.

Firmware builds and flashing are manual steps, separate from dotfiles
bootstrap.

## Update the layout

Keep the Configurator export in `keymaps.json` at the repository root.
Update `right_usb/keymap.json` from that export, filling empty layers with
74 `KC_NO` entries while preserving their positions and every populated
layer. Keep `MASTER_RIGHT` in `right_usb/config.h`, then rebuild using the
commands above.

The Configurator export contains the key bindings; the handedness override
is supplied by `config.h` during the local QMK build. Track these source
files in dotfiles. Generated firmware files are ignored in this directory.
