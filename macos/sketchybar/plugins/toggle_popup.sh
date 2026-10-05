#!/bin/bash

ITEM="${1:?item name required}"
STATE_FILE="/tmp/sketchybar-open-popup"
SKETCHYBAR="$(command -v sketchybar 2>/dev/null || true)"
[ -n "$SKETCHYBAR" ] || SKETCHYBAR="/opt/homebrew/bin/sketchybar"

close_popups() {
    [ -e "$STATE_FILE" ] || return 0

    "$SKETCHYBAR" \
        --set cpu popup.drawing=off \
        --set wifi popup.drawing=off \
        --set battery popup.drawing=off \
        --set clock popup.drawing=off
    rm -f "$STATE_FILE"
}

if [ "$ITEM" = "close" ]; then
    close_popups
    exit 0
fi

if [ "${BUTTON:-left}" = "right" ]; then
    close_popups
    case "$ITEM" in
        cpu) open -a "Activity Monitor" ;;
        wifi) open "x-apple.systempreferences:com.apple.Wi-Fi-Settings.extension" ;;
        battery) open "x-apple.systempreferences:com.apple.settings.battery" ;;
        clock) open -a "Calendar" ;;
    esac
    exit 0
fi

CURRENT="$("$SKETCHYBAR" --query "$ITEM" | jq -r '.popup.drawing')"
if [ "$CURRENT" = "on" ]; then
    close_popups
else
    close_popups
    "$SKETCHYBAR" --set "$ITEM" popup.drawing=on
    printf '%s\n' "$ITEM" > "$STATE_FILE"
fi
