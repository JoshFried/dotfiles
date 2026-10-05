#!/bin/bash

ITEM_BG="${ITEM_BG:-0xff2A2A37}"
FG="${FG:-0xffDCD7BA}"
FG_DIM="${FG_DIM:-0xffC8C093}"
GREEN="${GREEN:-0xff98BB6C}"
RED="${RED:-0xffE46876}"
YELLOW="${YELLOW:-0xffE6C384}"
PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

BACKGROUND_DRAWING=off
BACKGROUND_COLOR=$ITEM_BG
LABEL_COLOR=$FG
LABEL="${PERCENTAGE}%"
UPDATE_FREQ=120

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
elif [ "$PERCENTAGE" -gt 10 ]; then
    ICON="󰁺"
    COLOR=0xff16161D
    LABEL_COLOR=0xff16161D
    LABEL="LOW ${PERCENTAGE}%"
    BACKGROUND_DRAWING=on
    BACKGROUND_COLOR=$YELLOW
    UPDATE_FREQ=30
else
    ICON="󰁺"
    COLOR=0xff16161D
    LABEL_COLOR=0xff16161D
    LABEL="CRITICAL ${PERCENTAGE}%"
    BACKGROUND_DRAWING=on
    BACKGROUND_COLOR=$RED
    UPDATE_FREQ=15
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$COLOR" \
    label="$LABEL" \
    label.color="$LABEL_COLOR" \
    background.drawing="$BACKGROUND_DRAWING" \
    background.color="$BACKGROUND_COLOR" \
    update_freq="$UPDATE_FREQ"
