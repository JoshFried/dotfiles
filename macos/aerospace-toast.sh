#!/bin/bash
LAYOUT=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null)
hs -c "hs.alert.show('$LAYOUT', 0.8)"
