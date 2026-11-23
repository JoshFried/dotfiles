#!/bin/bash
# Sample top twice so the displayed CPU usage comes from a measured interval. Set the
# item label from the user and system percentages.

CPU="$(top -l 2 -n 0 -s 1 | grep "CPU usage" | tail -1 | awk '{print int($3+$5)}')%"
sketchybar --set "$NAME" label="$CPU"
