#!/bin/bash
# Format the current local date and time into the label of the invoking SketchyBar
# item.

if [ "$SENDER" = "mouse.exited.global" ]; then
    "$CONFIG_DIR/plugins/toggle_popup.sh" close
    exit 0
fi

sketchybar --set "$NAME" label="$(date '+%a %b %d  %I:%M %p')"
