#!/bin/bash
# Render the camera indicator from zoom_camera_change events emitted by the
# meeting integration.


GREEN=0xff98BB6C
RED=0xffE46876

if [ "$SENDER" != "zoom_camera_change" ]; then
    open -g "hammerspoon://zoom-camera-status"
    exit
fi

if [ "$ACTIVE" != "true" ]; then
    sketchybar --set "$NAME" \
        drawing=on \
        icon=󰕧 \
        icon.color=0xff957FB8 \
        label.drawing=off
elif [ "$CAMERA_ON" = "true" ]; then
    sketchybar --set "$NAME" \
        drawing=on \
        icon=󰕧 \
        icon.color="$GREEN" \
        label.drawing=off
else
    sketchybar --set "$NAME" \
        drawing=on \
        icon=󰕨 \
        icon.color="$RED" \
        label="Off" \
        label.color="$RED" \
        label.drawing=on
fi
