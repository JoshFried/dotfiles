#!/bin/bash

GREEN=0xff98BB6C
RED=0xffE46876

if [ "$SENDER" != "microphone_change" ]; then
    open -g "hammerspoon://microphone-status"
    exit
fi

if [ "$MUTED" = "true" ]; then
    sketchybar --set "$NAME" \
        icon=󰍭 \
        icon.color="$RED" \
        label="Muted" \
        label.color="$RED" \
        label.drawing=on
else
    sketchybar --set "$NAME" \
        icon=󰍬 \
        icon.color="$GREEN" \
        label="$DEVICE" \
        label.drawing=off
fi
