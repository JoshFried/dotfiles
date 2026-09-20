#!/bin/bash
# Assign workspaces to monitors based on monitor count
# Runs on startup and when monitors change (via Hammerspoon screen watcher)

AEROSPACE="/opt/homebrew/bin/aerospace"

if [ ! -x "$AEROSPACE" ]; then
    echo "AeroSpace executable not found at $AEROSPACE" >&2
    exit 127
fi

MONITOR_COUNT=$("$AEROSPACE" list-monitors --count)
MONITORS=$("$AEROSPACE" list-monitors --format '%{monitor-id}|%{monitor-name}|%{monitor-is-main}')
MAIN=$(printf '%s\n' "$MONITORS" | awk -F'|' '$3 == "true" { print $1; exit }')
EXTERNALS=$(printf '%s\n' "$MONITORS" | awk -F'|' 'tolower($2) !~ /built-in/ { print $1 }')

if [ -z "$MAIN" ]; then
    echo "Unable to identify the main display" >&2
    exit 1
fi

EXTERNAL_IDS=()
while IFS= read -r monitor_id; do
    [ -n "$monitor_id" ] && EXTERNAL_IDS[${#EXTERNAL_IDS[@]}]="$monitor_id"
done <<< "$EXTERNALS"

move_ws() {
    local ws=$1 mid=$2
    "$AEROSPACE" move-workspace-to-monitor --workspace "$ws" "$mid"
}

assign_external_workspaces() {
    local external_count=${#EXTERNAL_IDS[@]}
    local workspace=5
    local base_count
    local extra_count
    local display_index
    local workspace_count
    local offset

    if [ "$external_count" -eq 0 ]; then
        for workspace in 5 6 7 8 9 10; do move_ws "$workspace" "$MAIN"; done
        return
    fi

    base_count=$((6 / external_count))
    extra_count=$((6 % external_count))

    for ((display_index = 0; display_index < external_count; display_index++)); do
        workspace_count=$base_count
        [ "$display_index" -lt "$extra_count" ] && workspace_count=$((workspace_count + 1))

        for ((offset = 0; offset < workspace_count; offset++)); do
            move_ws "$workspace" "${EXTERNAL_IDS[$display_index]}"
            workspace=$((workspace + 1))
        done
    done
}

case $MONITOR_COUNT in
    1)
        echo "One monitor detected; no workspace reassignment needed"
        ;;
    ''|*[!0-9]*)
        echo "Unable to determine monitor count" >&2
        exit 1
        ;;
    *)
        for ws in 1 2 3 4; do move_ws "$ws" "$MAIN"; done
        assign_external_workspaces
        echo "Assigned workspaces 1-4 to main display $MAIN and split 5-10 across ${#EXTERNAL_IDS[@]} external display(s)"
        ;;
esac
