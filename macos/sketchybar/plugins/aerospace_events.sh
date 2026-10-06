#!/bin/bash

PID_FILE="/tmp/sketchybar-aerospace-events-${UID}.pid"
FIFO="/tmp/sketchybar-aerospace-events-${UID}.fifo"
ERROR_LOG="/tmp/sketchybar-aerospace-events-${UID}.log"
AEROSPACE="${AEROSPACE_BIN:-/opt/homebrew/bin/aerospace}"
SKETCHYBAR="${SKETCHYBAR_BIN:-/opt/homebrew/bin/sketchybar}"
SUBSCRIPTION_PID=

cleanup() {
    if [ -n "$SUBSCRIPTION_PID" ]; then
        kill "$SUBSCRIPTION_PID" 2>/dev/null || true
        wait "$SUBSCRIPTION_PID" 2>/dev/null || true
    fi

    if [ -r "$PID_FILE" ] && [ "$(cat "$PID_FILE")" = "$$" ]; then
        rm -f "$PID_FILE"
    fi
    rm -f "$FIFO"
}

stop_previous_listener() {
    local previous_pid
    local previous_command
    local attempt

    [ -r "$PID_FILE" ] || return
    previous_pid="$(cat "$PID_FILE")"
    case "$previous_pid" in
        ''|*[!0-9]*|$$) return ;;
    esac

    if ! kill -0 "$previous_pid" 2>/dev/null; then
        return
    fi

    previous_command="$(ps -p "$previous_pid" -o command= 2>/dev/null)"
    case "$previous_command" in
        *"/aerospace_events.sh") ;;
        *)
            rm -f "$PID_FILE"
            return
            ;;
    esac

    kill "$previous_pid" 2>/dev/null || true
    for attempt in {1..20}; do
        kill -0 "$previous_pid" 2>/dev/null || return
        sleep 0.05
    done

    echo "Previous AeroSpace event listener did not stop: $previous_pid" >&2
    exit 1
}

trap cleanup EXIT
trap 'exit 0' INT TERM
stop_previous_listener
printf '%s\n' "$$" > "$PID_FILE"

while true; do
    rm -f "$FIFO"
    mkfifo "$FIFO"

    "$AEROSPACE" subscribe --no-send-initial \
        focus-changed \
        focused-monitor-changed \
        focused-workspace-changed \
        window-detected \
        > "$FIFO" 2>> "$ERROR_LOG" &
    SUBSCRIPTION_PID=$!

    "$SKETCHYBAR" --trigger aerospace_state_change AEROSPACE_EVENT_TYPE=initial

    while IFS= read -r event; do
        event_type="$(printf '%s\n' "$event" |
            sed -n 's/.*"_event":"\([^"]*\)".*/\1/p')"
        "$SKETCHYBAR" --trigger aerospace_state_change \
            "AEROSPACE_EVENT_TYPE=${event_type:-unknown}"
    done < "$FIFO"

    wait "$SUBSCRIPTION_PID" 2>/dev/null || true
    SUBSCRIPTION_PID=
    sleep 1
done
