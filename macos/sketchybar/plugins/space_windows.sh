#!/bin/bash

source "$CONFIG_DIR/plugins/centered_apps.sh"

if [ "$SENDER" = "space_windows_change" ]; then
    space="$(echo "$INFO" | jq -r '.space')"
    apps="$(echo "$INFO" | jq -r '.apps | keys[]')"

    icon_strip=" "
    if [ -n "$apps" ]; then
        while read -r app; do
            is_centered_app "$app" && continue
            icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
        done <<< "$apps"
    else
        icon_strip=" —"
    fi

    sketchybar --set space.$space label="$icon_strip"
fi
