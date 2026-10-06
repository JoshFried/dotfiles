#!/bin/bash
# Preserve window workspace membership and assign workspaces based on monitor count.
# Runs on startup and when monitors change (via Hammerspoon screen watcher).

STATE_FILE="${AEROSPACE_WORKSPACE_STATE:-${TMPDIR:-/tmp}/aerospace-workspaces-${UID}.state}"

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

monitor_count() {
    "$AEROSPACE" list-monitors --format '%{monitor-id}' |
        awk 'NF { count++ } END { print count + 0 }'
}

snapshot_workspaces() {
    local expected_count=${1:-}
    local count_before
    local count_after
    local snapshot
    local temp_file

    count_before=$(monitor_count) || return 1
    if [ -n "$expected_count" ] && [ "$count_before" != "$expected_count" ]; then
        return 75
    fi

    snapshot=$("$AEROSPACE" list-windows --all --format '%{window-id}|%{workspace}') || return 1
    count_after=$(monitor_count) || return 1
    if [ "$count_before" != "$count_after" ] ||
        { [ -n "$expected_count" ] && [ "$count_after" != "$expected_count" ]; }; then
        return 75
    fi

    temp_file=$(mktemp "${STATE_FILE}.XXXXXX") || return 1
    if [ -n "$snapshot" ]; then
        printf '%s\n' "$snapshot" > "$temp_file"
    else
        : > "$temp_file"
    fi
    mv "$temp_file" "$STATE_FILE"
}

if [ "${1:-}" = "snapshot" ]; then
    snapshot_workspaces "${2:-}"
    exit $?
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

restore_window_workspaces() {
    local current_windows
    local window_id
    local workspace
    local current_workspace
    local restored=0

    [ -r "$STATE_FILE" ] || return
    current_windows=$("$AEROSPACE" list-windows --all --format '%{window-id}|%{workspace}') || return 1

    while IFS='|' read -r window_id workspace; do
        [ -n "$window_id" ] && [ -n "$workspace" ] || continue
        current_workspace=$(printf '%s\n' "$current_windows" |
            awk -F'|' -v id="$window_id" '$1 == id { print $2; exit }')
        [ -n "$current_workspace" ] || continue
        [ "$current_workspace" = "$workspace" ] && continue

        if "$AEROSPACE" move-node-to-workspace --window-id "$window_id" "$workspace"; then
            restored=$((restored + 1))
        fi
    done < "$STATE_FILE"

    [ "$restored" -gt 0 ] && echo "Restored $restored window(s) to their previous workspaces"
}

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

restore_window_workspaces

case $MONITOR_COUNT in
    1)
        for ws in 1 2 3 4 5 6 7 8 9 10; do move_ws "$ws" "$PRIMARY"; done
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

if [ "$MONITOR_COUNT" -eq 1 ]; then
    echo "Assigned workspaces 1-10 to primary display $PRIMARY"
else
    echo "Assigned workspaces 1-4 to primary display $PRIMARY and split 5-10 across ${#EXTERNAL_IDS[@]} external display(s)"
fi
