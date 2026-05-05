#!/usr/bin/env bash
# Wrapper that passes -C ~/.work.sesh.toml to sesh when that file exists.
# Used by tmux popups and the tv sesh channel so the same config resolution
# works regardless of whether a shell rc has been sourced.
set -e

if [ -f "$HOME/.work.sesh.toml" ]; then
    exec /opt/homebrew/bin/sesh -C "$HOME/.work.sesh.toml" "$@"
else
    exec /opt/homebrew/bin/sesh "$@"
fi
