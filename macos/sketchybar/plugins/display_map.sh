#!/bin/bash
# Join AppKit and SketchyBar display records by physical ID. The resulting
# array maps an AeroSpace screen index to the correct SketchyBar arrangement.


load_display_map() {
    local displays screen_ids mapped_ids appkit_id arrangement_id
    SKETCHYBAR_DISPLAYS=()
    displays="$(sketchybar --query displays 2>/dev/null)" || return 1
    screen_ids="$(osascript -l JavaScript "$CONFIG_DIR/plugins/display_ids.js" 2>/dev/null)" || return 1

    # AppKit screen indexes and SketchyBar arrangement IDs can have different orders.
    mapped_ids="$(jq -r --arg screen_ids "$screen_ids" '
        . as $displays |
        $screen_ids | split("\n")[] | split("|") |
        select(length == 2) |
        (.[0] | tonumber) as $appkit_id |
        (.[1] | tonumber) as $display_id |
        $displays[] |
        select(.DirectDisplayID == $display_id) |
        "\($appkit_id)|\(."arrangement-id")"
    ' <<< "$displays" 2>/dev/null)" || return 1

    while IFS='|' read -r appkit_id arrangement_id; do
        case "$appkit_id:$arrangement_id" in
            *[!0-9:]*|:*|*:) continue ;;
        esac
        SKETCHYBAR_DISPLAYS[$appkit_id]="$arrangement_id"
    done <<< "$mapped_ids"
}
