#!/bin/bash

STATE_FILE="/tmp/sketchybar-system-stats-${UID}"
NOW="$(date +%s)"

CPU="$(top -l 1 -n 0 | awk '/CPU usage/ { gsub("%", "", $7); printf "%.0f", 100 - $7 }')"
MEMORY="$(memory_pressure -Q 2>/dev/null | awk '/free percentage/ { gsub("%", "", $5); print 100 - $5 }')"
DISK="$(df -H / | awk 'NR == 2 { print $5 }')"
LOAD="$(sysctl -n vm.loadavg | awk '{ printf "%s %s %s", $2, $3, $4 }')"

INTERFACE="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }')"
IP_ADDRESS="$(ipconfig getifaddr "$INTERFACE" 2>/dev/null || true)"
read -r INPUT_BYTES OUTPUT_BYTES < <(
    netstat -ibn 2>/dev/null | awk -v interface="$INTERFACE" '
        $1 == interface && $7 ~ /^[0-9]+$/ && $10 ~ /^[0-9]+$/ {
            if ($7 > input) input = $7
            if ($10 > output) output = $10
        }
        END { print input + 0, output + 0 }
    '
)

DOWNLOAD_RATE=0
UPLOAD_RATE=0
if [ -r "$STATE_FILE" ]; then
    read -r PREVIOUS_TIME PREVIOUS_INPUT PREVIOUS_OUTPUT < "$STATE_FILE"
    ELAPSED=$((NOW - PREVIOUS_TIME))
    if [ "$ELAPSED" -gt 0 ]; then
        DOWNLOAD_RATE=$(((INPUT_BYTES - PREVIOUS_INPUT) / ELAPSED))
        UPLOAD_RATE=$(((OUTPUT_BYTES - PREVIOUS_OUTPUT) / ELAPSED))
    fi
fi
printf '%s %s %s\n' "$NOW" "$INPUT_BYTES" "$OUTPUT_BYTES" > "$STATE_FILE"

format_rate() {
    awk -v bytes="$1" 'BEGIN {
        if (bytes >= 1048576) printf "%.1f MB/s", bytes / 1048576
        else if (bytes >= 1024) printf "%.0f KB/s", bytes / 1024
        else printf "%d B/s", bytes
    }'
}

BATTERY_OUTPUT="$(pmset -g batt)"
POWER_SOURCE="$(printf '%s\n' "$BATTERY_OUTPUT" | awk -F"'" 'NR == 1 { print $2 }')"
BATTERY_TIME="$(printf '%s\n' "$BATTERY_OUTPUT" | sed -nE 's/.*; ([0-9]+:[0-9]+) remaining.*/\1 remaining/p')"
[ -n "$BATTERY_TIME" ] || BATTERY_TIME="Calculating"

BATTERY_DATA="$(ioreg -rn AppleSmartBattery 2>/dev/null)"
BATTERY_CYCLES="$(printf '%s\n' "$BATTERY_DATA" |
    awk '$1 == "\"CycleCount\"" && $2 == "=" { print $3; exit }')"
DESIGN_CAPACITY="$(printf '%s\n' "$BATTERY_DATA" |
    awk '$1 == "\"DesignCapacity\"" && $2 == "=" { print $3; exit }')"
MAX_CAPACITY="$(printf '%s\n' "$BATTERY_DATA" |
    awk '$1 == "\"AppleRawMaxCapacity\"" && $2 == "=" { print $3; exit }')"
BATTERY_HEALTH="Unknown"
if [ "${DESIGN_CAPACITY:-0}" -gt 0 ] 2>/dev/null && [ "${MAX_CAPACITY:-0}" -gt 0 ] 2>/dev/null; then
    BATTERY_HEALTH="$((MAX_CAPACITY * 100 / DESIGN_CAPACITY))%"
fi

sketchybar --trigger system_stats_update \
    CPU="${CPU:-0}" \
    MEMORY="${MEMORY:-0}" \
    DISK="${DISK:---}" \
    LOAD="${LOAD:---}" \
    INTERFACE="${INTERFACE:---}" \
    IP_ADDRESS="${IP_ADDRESS:-Disconnected}" \
    DOWNLOAD_RATE="$(format_rate "$DOWNLOAD_RATE")" \
    UPLOAD_RATE="$(format_rate "$UPLOAD_RATE")" \
    POWER_SOURCE="${POWER_SOURCE:---}" \
    BATTERY_TIME="$BATTERY_TIME" \
    BATTERY_HEALTH="$BATTERY_HEALTH" \
    BATTERY_CYCLES="${BATTERY_CYCLES:---}"
