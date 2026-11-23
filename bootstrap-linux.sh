#!/usr/bin/env bash
# Compatibility entry point for existing Linux installs. Find the shared checkout
# even when this launcher was symlinked or copied outside it with --repo.
set -euo pipefail

locate_shared_bootstrap() {
    local launcher="${BASH_SOURCE[0]}" target candidate override="${DOTFILES_REPO:-}"
    while [ "$#" -gt 0 ]; do
        if [ "$1" = --repo ]; then
            override=${2:?Missing value for --repo}
            shift
        fi
        shift
    done
    while [ -L "$launcher" ]; do
        target=$(readlink "$launcher")
        case "$target" in
            /*) launcher=$target ;;
            *) launcher="$(dirname "$launcher")/$target" ;;
        esac
    done
    for candidate in "$override" "$(dirname "$launcher")" "$PWD" "$(git rev-parse --show-toplevel 2>/dev/null || true)" "$HOME/repos/dotfiles" "$HOME/dotfiles" "$HOME/.dotfiles"; do
        if [ -n "$candidate" ] && [ -f "$candidate/linux/bootstrap.sh" ] && [ -f "$candidate/bootstrap.sh" ]; then
            (cd "$candidate" && pwd -P)
            return
        fi
    done
    echo 'Cannot find shared bootstrap. Pass --repo PATH to a complete checkout.' >&2
    return 1
}

shared_root=$(locate_shared_bootstrap "$@")
source "$shared_root/bootstrap.sh"
source "$shared_root/linux/bootstrap.sh"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    if [ "$(uname -s)" != Linux ]; then
        echo 'This installer only supports Linux' >&2
        exit 1
    fi
    main "$@"
fi
