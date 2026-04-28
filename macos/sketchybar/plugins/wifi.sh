#!/bin/bash
IP="$(ipconfig getifaddr en0 2>/dev/null)"
if [ -z "$IP" ]; then
    sketchybar --set "$NAME" icon=󰖪 label="Off"
else
    sketchybar --set "$NAME" icon=󰖩 label="Connected"
fi
