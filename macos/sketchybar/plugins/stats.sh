#!/bin/bash

ORANGE="${ORANGE:-0xffFFA066}"
RED="${RED:-0xffE46876}"
FG_DIM="${FG_DIM:-0xffC8C093}"

if [ "$SENDER" = "mouse.exited.global" ]; then
    "$CONFIG_DIR/plugins/toggle_popup.sh" close
    exit 0
fi

CPU_COLOR=$FG_DIM
if [ "${CPU:-0}" -ge 85 ]; then
    CPU_COLOR=$RED
elif [ "${CPU:-0}" -ge 60 ]; then
    CPU_COLOR=$ORANGE
fi

sketchybar \
    --set cpu label="${CPU:-0}%" icon.color="$CPU_COLOR" \
    --set cpu.memory label="${MEMORY:-0}% used" \
    --set cpu.load label="${LOAD:---}" \
    --set cpu.disk label="${DISK:---} used" \
    --set wifi.interface label="${INTERFACE:---} · ${IP_ADDRESS:-Disconnected}" \
    --set wifi.download label="${DOWNLOAD_RATE:---}" \
    --set wifi.upload label="${UPLOAD_RATE:---}" \
    --set battery.source label="${POWER_SOURCE:---}" \
    --set battery.remaining label="${BATTERY_TIME:---}" \
    --set battery.health label="${BATTERY_HEALTH:---} · ${BATTERY_CYCLES:---} cycles"
