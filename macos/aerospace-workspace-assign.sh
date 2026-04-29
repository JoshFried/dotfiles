#!/bin/bash
# Assign workspaces to monitors based on monitor count
MONITORS=$(aerospace list-monitors --count 2>/dev/null)

case $MONITORS in
    1)
        # All workspaces on the single monitor — nothing to do
        ;;
    2)
        # 1-5 on main, 6-10 on secondary
        for ws in 1 2 3 4 5; do
            aerospace move-workspace-to-monitor --workspace "$ws" main 2>/dev/null
        done
        for ws in 6 7 8 9 10; do
            aerospace move-workspace-to-monitor --workspace "$ws" secondary 2>/dev/null
        done
        ;;
    3)
        # 1-3 on monitor 1, 4-6 on monitor 2, 7-10 on monitor 3
        for ws in 1 2 3; do
            aerospace move-workspace-to-monitor --workspace "$ws" 1 2>/dev/null
        done
        for ws in 4 5 6; do
            aerospace move-workspace-to-monitor --workspace "$ws" 2 2>/dev/null
        done
        for ws in 7 8 9 10; do
            aerospace move-workspace-to-monitor --workspace "$ws" 3 2>/dev/null
        done
        ;;
esac
