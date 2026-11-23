#!/bin/bash
# Read the focused window layout from the AeroSpace CLI and send a short-lived alert
# through the Hammerspoon hs command.

LAYOUT=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null)
hs -c "hs.alert.show('$LAYOUT', 0.8)"
