#!/bin/bash
# Assign workspaces to monitors based on monitor count
# Runs on startup and when monitors change (via Hammerspoon screen watcher)

resolve_aerospace() {
    local candidate

    if [ -n "${AEROSPACE_BIN:-}" ] && [ -x "$AEROSPACE_BIN" ]; then
        printf '%s\n' "$AEROSPACE_BIN"
        return
    fi

    if command -v aerospace >/dev/null 2>&1; then
        command -v aerospace
        return
    fi

    for candidate in /opt/homebrew/bin/aerospace /usr/local/bin/aerospace; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return
        fi
    done

    return 1
}

if ! AEROSPACE=$(resolve_aerospace); then
    echo "AeroSpace executable not found" >&2
    exit 127
fi

if ! MONITORS=$("$AEROSPACE" list-monitors --format '%{monitor-id}|%{monitor-name}|%{monitor-is-main}'); then
    echo "Unable to query AeroSpace monitors" >&2
    exit 1
fi

MONITOR_COUNT=$(printf '%s\n' "$MONITORS" | awk 'NF { count++ } END { print count + 0 }')
MAIN=$(printf '%s\n' "$MONITORS" | awk -F'|' '$3 == "true" { print $1; exit }')
BUILT_IN=$(printf '%s\n' "$MONITORS" | awk -F'|' 'tolower($2) ~ /built-in/ { print $1; exit }')
EXTERNALS=$(printf '%s\n' "$MONITORS" | awk -F'|' 'tolower($2) !~ /built-in/ { print $1 }')
PRIMARY=${BUILT_IN:-$MAIN}
MOVE_FAILURES=0

if [ -z "$PRIMARY" ]; then
    echo "Unable to identify the primary workspace display" >&2
    exit 1
fi

EXTERNAL_IDS=()
while IFS= read -r monitor_id; do
    [ -n "$monitor_id" ] && EXTERNAL_IDS[${#EXTERNAL_IDS[@]}]="$monitor_id"
done <<< "$EXTERNALS"

move_ws() {
    local ws=$1 mid=$2

    if "$AEROSPACE" move-workspace-to-monitor --workspace "$ws" "$mid"; then
        return
    fi

    echo "Failed to move workspace $ws to monitor $mid" >&2
    MOVE_FAILURES=$((MOVE_FAILURES + 1))
    return 1
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
        for workspace in 5 6 7 8 9 10; do move_ws "$workspace" "$PRIMARY"; done
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
        for ws in 1 2 3 4; do move_ws "$ws" "$PRIMARY"; done
        assign_external_workspaces
        ;;
esac

if [ "$MOVE_FAILURES" -gt 0 ]; then
    echo "Workspace assignment failed for $MOVE_FAILURES workspace(s)" >&2
    exit 1
fi

if [ "$MONITOR_COUNT" -gt 1 ]; then
    echo "Assigned workspaces 1-4 to primary display $PRIMARY and split 5-10 across ${#EXTERNAL_IDS[@]} external display(s)"
fi
