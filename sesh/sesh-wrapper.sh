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

WORK_CONFIG="$HOME/.work.sesh.toml"

if [ -f "$WORK_CONFIG" ]; then
    exec "$SESH" -C "$WORK_CONFIG" "$@"
fi

exec "$SESH" "$@"
