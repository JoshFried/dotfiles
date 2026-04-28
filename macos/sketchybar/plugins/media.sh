#!/bin/bash

TITLE="$(nowplaying-cli get title 2>/dev/null)"
ARTIST="$(nowplaying-cli get artist 2>/dev/null)"
STATE="$(nowplaying-cli get playbackRate 2>/dev/null)"
BUNDLE="$(nowplaying-cli get-raw 2>/dev/null | grep BundleIdentifier | awk -F'"' '{print $4}')"

# Check if the source app is a foreground app (not background-only zombie)
APP_TYPE="$(lsappinfo info -only ApplicationType "$BUNDLE" 2>/dev/null)"

if [ -z "$TITLE" ] || [ "$TITLE" = "null" ] || [[ "$APP_TYPE" != *"Foreground"* ]]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

[ ${#TITLE} -gt 30 ] && TITLE="${TITLE:0:27}..."

if [ "$STATE" = "1" ] || [ "$STATE" = "1.0" ]; then
    ICON="󰎈"
else
    ICON="󰏤"
fi

LABEL="$TITLE — $ARTIST"
sketchybar --set "$NAME" drawing=on icon="$ICON" label="$LABEL"
