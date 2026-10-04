#!/usr/bin/env bash
set -euo pipefail

if command -v sesh >/dev/null 2>&1; then
    SESH=$(command -v sesh)
elif [ -x /opt/homebrew/bin/sesh ]; then
    SESH=/opt/homebrew/bin/sesh
elif [ -x /home/linuxbrew/.linuxbrew/bin/sesh ]; then
    SESH=/home/linuxbrew/.linuxbrew/bin/sesh
elif [ -x /usr/local/bin/sesh ]; then
    SESH=/usr/local/bin/sesh
else
    echo "sesh executable not found" >&2
    exit 127
fi

BASE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/sesh/sesh.toml"
WORK_CONFIG="$HOME/.work.sesh.toml"

if [ ! -f "$WORK_CONFIG" ]; then
    exec "$SESH" "$@"
fi

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sesh"
COMBINED_CONFIG="$CACHE_DIR/combined.toml"
mkdir -p "$CACHE_DIR"

TEMP_CONFIG=$(mktemp "$CACHE_DIR/combined.XXXXXX")
trap 'rm -f "$TEMP_CONFIG"' EXIT

if [ -f "$BASE_CONFIG" ]; then
    cat "$BASE_CONFIG" >"$TEMP_CONFIG"
fi
printf '\n' >>"$TEMP_CONFIG"
cat "$WORK_CONFIG" >>"$TEMP_CONFIG"
mv "$TEMP_CONFIG" "$COMBINED_CONFIG"
trap - EXIT

exec "$SESH" -C "$COMBINED_CONFIG" "$@"
