#!/bin/bash
# Assign workspaces to monitors based on monitor count
# Runs on startup and when monitors change (via Hammerspoon screen watcher)

AEROSPACE="/opt/homebrew/bin/aerospace"

if [ ! -x "$AEROSPACE" ]; then
    echo "AeroSpace executable not found at $AEROSPACE" >&2
    exit 127
fi

MONITOR_COUNT=$("$AEROSPACE" list-monitors --count)
MONITORS=$("$AEROSPACE" list-monitors --format '%{monitor-id}|%{monitor-name}')
BUILTIN=$(printf '%s\n' "$MONITORS" | grep -i "built-in" | cut -d'|' -f1 | xargs)
EXTERNALS=$(printf '%s\n' "$MONITORS" | grep -iv "built-in" | cut -d'|' -f1 | xargs)

move_ws() {
    local ws=$1 mid=$2
    "$AEROSPACE" move-workspace-to-monitor --workspace "$ws" "$mid"
}

case $MONITOR_COUNT in
    1)
        echo "One monitor detected; no workspace reassignment needed"
        ;;
    2)
        EXT=$(echo "$EXTERNALS" | head -1)
        for ws in 1 2 3 4 5; do move_ws "$ws" "$EXT"; done
        for ws in 6 7 8 9 10; do move_ws "$ws" "$BUILTIN"; done
        echo "Assigned workspaces 1-5 to the external display and 6-10 to the built-in display"
        ;;
    3|*)
        EXT1=$(echo "$EXTERNALS" | head -1)
        EXT2=$(echo "$EXTERNALS" | tail -1)
        for ws in 1 2 3; do move_ws "$ws" "$EXT1"; done
        for ws in 4 5 6; do move_ws "$ws" "$BUILTIN"; done
        for ws in 7 8 9 10; do move_ws "$ws" "$EXT2"; done
        echo "Assigned workspaces across two external displays and the built-in display"
        ;;
    *)
        echo "Unable to determine monitor count" >&2
        exit 1
        ;;
esac
