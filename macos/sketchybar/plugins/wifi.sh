#!/bin/bash
# Look up en0's IPv4 address to decide whether the bar displays a connected or
# offline indicator.

if [ "$SENDER" = "mouse.exited.global" ]; then
    "$CONFIG_DIR/plugins/toggle_popup.sh" close
    exit 0
fi

IP="$(ipconfig getifaddr en0 2>/dev/null)"
if [ -z "$IP" ]; then
    sketchybar --set "$NAME" icon=󰖪 label="Off"
else
    sketchybar --set "$NAME" icon=󰖩 label="Connected"
fi
