#!/bin/bash
# Assign workspaces to monitors based on monitor count
# Runs on startup and when monitors change (via Hammerspoon screen watcher)

MONITOR_COUNT=$(aerospace list-monitors --count 2>/dev/null)
BUILTIN=$(aerospace list-monitors --format '%{monitor-id}|%{monitor-name}' 2>/dev/null | grep -i "built-in" | cut -d'|' -f1 | xargs)
EXTERNALS=$(aerospace list-monitors --format '%{monitor-id}|%{monitor-name}' 2>/dev/null | grep -iv "built-in" | cut -d'|' -f1 | xargs)

move_ws() {
    local ws=$1 mid=$2
    aerospace move-workspace-to-monitor --workspace "$ws" "$mid" 2>/dev/null
}

case $MONITOR_COUNT in
    1)
        # Single monitor — nothing to do
        ;;
    2)
        # External gets 1-5, built-in gets 6-10
        EXT=$(echo "$EXTERNALS" | head -1)
        for ws in 1 2 3 4 5; do move_ws "$ws" "$EXT"; done
        for ws in 6 7 8 9 10; do move_ws "$ws" "$BUILTIN"; done
        ;;
    3|*)
        # Two externals + built-in
        EXT1=$(echo "$EXTERNALS" | head -1)
        EXT2=$(echo "$EXTERNALS" | tail -1)
        for ws in 1 2 3; do move_ws "$ws" "$EXT1"; done
        for ws in 4 5 6; do move_ws "$ws" "$BUILTIN"; done
        for ws in 7 8 9 10; do move_ws "$ws" "$EXT2"; done
        ;;
esac
