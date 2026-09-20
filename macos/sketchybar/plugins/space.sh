#!/bin/bash

FOCUSED="$(aerospace list-workspaces --focused 2>/dev/null)"
MONITORS="$(aerospace list-monitors --format '%{monitor-id}|%{monitor-name}|%{monitor-is-main}' 2>/dev/null)"
WORKSPACES="$(aerospace list-workspaces --monitor all --format '%{workspace}|%{monitor-id}' 2>/dev/null)"
WINDOWS="$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)"
SB_DISPLAYS="$(sketchybar --query displays 2>/dev/null)"

if [ -z "$MONITORS" ] || [ -z "$SB_DISPLAYS" ]; then
    exit 0
fi

SB_COUNT="$(printf '%s' "$SB_DISPLAYS" | jq -r 'length' 2>/dev/null)"
AERO_TO_SB=()
AERO_IDS=()
AERO_MAIN=""
AERO_BUILTIN=""

while IFS='|' read -r monitor_id monitor_name is_main; do
    [ -z "$monitor_id" ] && continue
    AERO_IDS[${#AERO_IDS[@]}]="$monitor_id"
    [ "$is_main" = "true" ] && AERO_MAIN="$monitor_id"
    case "$monitor_name" in
        *[Bb]uilt-[Ii]n*) AERO_BUILTIN="$monitor_id" ;;
    esac
done <<< "$MONITORS"

[ -n "$AERO_MAIN" ] && AERO_TO_SB[$AERO_MAIN]=1

if [ "$SB_COUNT" = "2" ]; then
    for monitor_id in "${AERO_IDS[@]}"; do
        [ "$monitor_id" = "$AERO_MAIN" ] && continue
        AERO_TO_SB[$monitor_id]=2
    done
elif [ "$SB_COUNT" = "3" ]; then
    SB_BUILTIN="$(printf '%s' "$SB_DISPLAYS" |
        jq -r 'min_by(.frame.w * .frame.h)["arrangement-id"]' 2>/dev/null)"
    SB_OTHER=""
    for display_id in 1 2 3; do
        [ "$display_id" = "1" ] && continue
        [ "$display_id" = "$SB_BUILTIN" ] && continue
        SB_OTHER="$display_id"
    done

    AERO_OTHER=""
    for monitor_id in "${AERO_IDS[@]}"; do
        [ "$monitor_id" = "$AERO_MAIN" ] && continue
        [ "$monitor_id" = "$AERO_BUILTIN" ] && continue
        AERO_OTHER="$monitor_id"
    done

    [ -n "$AERO_BUILTIN" ] && AERO_TO_SB[$AERO_BUILTIN]="$SB_BUILTIN"
    [ -n "$AERO_OTHER" ] && AERO_TO_SB[$AERO_OTHER]="$SB_OTHER"
fi

WORKSPACE_MONITORS=()
while IFS='|' read -r workspace monitor_id; do
    case "$workspace" in
        ''|*[!0-9]*) continue ;;
    esac
    WORKSPACE_MONITORS[$workspace]="$monitor_id"
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
    monitor_id="${WORKSPACE_MONITORS[$workspace]}"
    display_id="${AERO_TO_SB[$monitor_id]}"
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
