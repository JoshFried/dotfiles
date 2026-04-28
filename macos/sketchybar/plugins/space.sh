#!/bin/bash
if [ "$SELECTED" = "true" ]; then
    sketchybar --set "$NAME" icon.highlight=on background.color=$ACCENT background.drawing=on
else
    sketchybar --set "$NAME" icon.highlight=off background.color=$TRANSPARENT background.drawing=off
fi
