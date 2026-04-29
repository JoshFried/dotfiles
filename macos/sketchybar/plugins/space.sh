#!/bin/bash

FOCUSED="$(aerospace list-workspaces --focused 2>/dev/null)"

# Map AeroSpace monitor ID → SketchyBar display number
# AeroSpace: monitor with is-main=true corresponds to SketchyBar display 1 (always main)
# For the rest, match by checking if it's built-in (smallest resolution = laptop)
declare -A AERO_TO_SB

# Get SketchyBar display info
SB_DISPLAYS=$(sketchybar --query displays 2>/dev/null)
SB_COUNT=$(echo "$SB_DISPLAYS" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null)

# AeroSpace main monitor → SketchyBar display 1
AERO_MAIN=$(aerospace list-monitors --format '%{monitor-id}|%{monitor-is-main}' 2>/dev/null | grep "|true" | cut -d'|' -f1 | xargs)
AERO_TO_SB["$AERO_MAIN"]=1

if [ "$SB_COUNT" = "2" ]; then
    # 2 monitors: the other one is display 2
    for aid in $(aerospace list-monitors --format '%{monitor-id}' 2>/dev/null); do
        aid=$(echo "$aid" | xargs)
        [ "$aid" = "$AERO_MAIN" ] && continue
        AERO_TO_SB["$aid"]=2
    done
elif [ "$SB_COUNT" = "3" ]; then
    # 3 monitors: built-in is the small one, find it in SketchyBar
    SB_BUILTIN=$(echo "$SB_DISPLAYS" | python3 -c "
import json,sys
displays=json.load(sys.stdin)
# Built-in is the smallest display
smallest=min(displays, key=lambda d: d['frame']['w']*d['frame']['h'])
print(smallest['arrangement-id'])
" 2>/dev/null)
    # The remaining SB display is the other external
    SB_OTHER=""
    for sbd in 1 2 3; do
        [ "$sbd" = "1" ] && continue
        [ "$sbd" = "$SB_BUILTIN" ] && continue
        SB_OTHER=$sbd
    done

    # AeroSpace built-in monitor
    AERO_BUILTIN=$(aerospace list-monitors --format '%{monitor-id}|%{monitor-name}' 2>/dev/null | grep -i "built-in" | cut -d'|' -f1 | xargs)
    AERO_OTHER=""
    for aid in $(aerospace list-monitors --format '%{monitor-id}' 2>/dev/null); do
        aid=$(echo "$aid" | xargs)
        [ "$aid" = "$AERO_MAIN" ] && continue
        [ "$aid" = "$AERO_BUILTIN" ] && continue
        AERO_OTHER=$aid
    done

    AERO_TO_SB["$AERO_BUILTIN"]="$SB_BUILTIN"
    AERO_TO_SB["$AERO_OTHER"]="$SB_OTHER"
fi

for sid in 1 2 3 4 5 6 7 8 9 10; do
    WINDOWS="$(aerospace list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null)"

    WS_MONITOR="$(aerospace list-workspaces --monitor all --format '%{workspace}|%{monitor-id}' 2>/dev/null | grep "^${sid}|" | cut -d'|' -f2)"

    SB_DISPLAY="${AERO_TO_SB[$WS_MONITOR]}"
    if [ -n "$SB_DISPLAY" ]; then
        sketchybar --set space.$sid display="$SB_DISPLAY"
    fi

    ICONS=""
    if [ -n "$WINDOWS" ]; then
        while IFS= read -r app; do
            ICONS+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
        done <<< "$WINDOWS"
    fi

    if [ "$sid" = "$FOCUSED" ]; then
        sketchybar --set space.$sid \
            drawing=on \
            icon.highlight=on \
            background.drawing=on \
            background.color=0xff7E9CD8 \
            label="$ICONS" \
            label.drawing=on
    elif [ -n "$WINDOWS" ]; then
        sketchybar --set space.$sid \
            drawing=on \
            icon.highlight=off \
            background.drawing=off \
            background.color=0x00000000 \
            label="$ICONS" \
            label.drawing=on
    else
        sketchybar --set space.$sid drawing=off
    fi
done
