#!/bin/bash
PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ -n "$CHARGING" ]; then
    ICON="󰂄"
    COLOR=$GREEN
elif [ "$PERCENTAGE" -gt 80 ]; then
    ICON="󰁹"
    COLOR=$GREEN
elif [ "$PERCENTAGE" -gt 60 ]; then
    ICON="󰂀"
    COLOR=$FG
elif [ "$PERCENTAGE" -gt 40 ]; then
    ICON="󰁾"
    COLOR=$FG_DIM
elif [ "$PERCENTAGE" -gt 20 ]; then
    ICON="󰁻"
    COLOR=$YELLOW
else
    ICON="󰁺"
    COLOR=$RED
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
