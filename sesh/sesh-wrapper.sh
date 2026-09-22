#!/usr/bin/env bash
# Supports a private machine-specific config without requiring shell aliases.
set -e

if command -v sesh >/dev/null 2>&1; then
    SESH=$(command -v sesh)
elif [ -x /opt/homebrew/bin/sesh ]; then
    SESH=/opt/homebrew/bin/sesh
elif [ -x /usr/local/bin/sesh ]; then
    SESH=/usr/local/bin/sesh
else
    echo "sesh executable not found" >&2
    exit 127
fi

if [ -f "$HOME/.work.sesh.toml" ]; then
    exec "$SESH" -C "$HOME/.work.sesh.toml" "$@"
else
    exec "$SESH" "$@"
fi
