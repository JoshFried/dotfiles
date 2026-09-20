#!/bin/bash

FOCUSED="$(aerospace list-workspaces --focused 2>/dev/null)"
WORKSPACES="$(aerospace list-workspaces --monitor all --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}' 2>/dev/null)"
WINDOWS="$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)"

if [ -z "$WORKSPACES" ]; then
    exit 0
fi

WORKSPACE_DISPLAYS=()
while IFS='|' read -r workspace display_id; do
    case "$workspace" in
        ''|*[!0-9]*) continue ;;
    esac
    WORKSPACE_DISPLAYS[$workspace]="$display_id"
done <<< "$WORKSPACES"

source "$CONFIG_DIR/plugins/icon_map_fn.sh"

WORKSPACE_ICONS=()
while IFS='|' read -r workspace app; do
    case "$workspace" in
        ''|*[!0-9]*) continue ;;
    esac
    [ -z "$app" ] && continue

    icon_map "$app"
    case " ${WORKSPACE_ICONS[$workspace]} " in
        *" $icon_result "*) ;;
        *) WORKSPACE_ICONS[$workspace]="${WORKSPACE_ICONS[$workspace]} $icon_result" ;;
    esac
done <<< "$WINDOWS"

SKETCHYBAR_ARGS=()
for workspace in 1 2 3 4 5 6 7 8 9 10; do
    display_id="${WORKSPACE_DISPLAYS[$workspace]}"
    icons="${WORKSPACE_ICONS[$workspace]}"

    SKETCHYBAR_ARGS+=(--set "space.$workspace")
    [ -n "$display_id" ] && SKETCHYBAR_ARGS+=("display=$display_id")

    if [ "$workspace" = "$FOCUSED" ]; then
        SKETCHYBAR_ARGS+=(
            drawing=on
            icon.highlight=on
            background.drawing=on
            background.color=0xff7E9CD8
            "label=$icons"
            label.drawing=on
        )
    elif [ -n "$icons" ]; then
        SKETCHYBAR_ARGS+=(
            drawing=on
            icon.highlight=off
            background.drawing=off
            background.color=0x00000000
            "label=$icons"
            label.drawing=on
        )
    else
        SKETCHYBAR_ARGS+=(drawing=off)
    fi
done

sketchybar "${SKETCHYBAR_ARGS[@]}"
