#!/bin/bash

FOCUSED="$(aerospace list-workspaces --focused 2>/dev/null)"

for sid in 1 2 3 4 5 6 7 8 9 10; do
    WINDOWS="$(aerospace list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null)"

    # Build app icon strip
    ICONS=""
    if [ -n "$WINDOWS" ]; then
        while IFS= read -r app; do
            ICONS+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
        done <<< "$WINDOWS"
    fi

    if [ "$sid" = "$FOCUSED" ]; then
        # Active: show highlighted with app icons
        sketchybar --set space.$sid \
            drawing=on \
            icon.highlight=on \
            background.drawing=on \
            background.color=0xff7E9CD8 \
            label="$ICONS" \
            label.drawing=on
    elif [ -n "$WINDOWS" ]; then
        # Has windows: show with app icons
        sketchybar --set space.$sid \
            drawing=on \
            icon.highlight=off \
            background.drawing=off \
            background.color=0x00000000 \
            label="$ICONS" \
            label.drawing=on
    else
        # Empty: hide
        sketchybar --set space.$sid drawing=off
    fi
done
