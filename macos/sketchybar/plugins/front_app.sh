#!/bin/bash
# Handle front_app_switched. INFO supplies the application name used for the label
# and the icon lookup.


source "$CONFIG_DIR/plugins/centered_apps.sh"

if [ "$SENDER" = "front_app_switched" ]; then
    if is_centered_app "$INFO"; then
        sketchybar --set "$NAME" drawing=off
    else
        sketchybar --set "$NAME" \
            drawing=on \
            label="$INFO" \
            icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$INFO")"
    fi
fi
