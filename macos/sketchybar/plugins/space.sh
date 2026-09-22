#!/bin/bash

WORKSPACES="$(aerospace list-workspaces --monitor all --format '%{workspace}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-is-visible}|%{workspace-is-focused}' 2>/dev/null)"
WINDOWS="$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)"

if [ -z "$WORKSPACES" ]; then
    exit 0
fi

WORKSPACE_DISPLAYS=()
WORKSPACE_VISIBLE=()
WORKSPACE_FOCUSED=()
while IFS='|' read -r workspace display_id is_visible is_focused; do
    case "$workspace" in
        ''|*[!0-9]*) continue ;;
    esac
    WORKSPACE_DISPLAYS[$workspace]="$display_id"
    WORKSPACE_VISIBLE[$workspace]="$is_visible"
    WORKSPACE_FOCUSED[$workspace]="$is_focused"
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
    is_visible="${WORKSPACE_VISIBLE[$workspace]}"
    is_focused="${WORKSPACE_FOCUSED[$workspace]}"

    SKETCHYBAR_ARGS+=(--set "space.$workspace")
    [ -n "$display_id" ] && SKETCHYBAR_ARGS+=("display=$display_id")

    if [ "$is_visible" = "true" ]; then
        if [ "$is_focused" = "true" ]; then
            background_color=0xff7E9CD8
        else
            background_color=0xff54546D
        fi

        SKETCHYBAR_ARGS+=(
            drawing=on
            icon.highlight=on
            background.drawing=on
            "background.color=$background_color"
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
