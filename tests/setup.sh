#!/usr/bin/env bash
# Run with bash tests/setup.sh. An isolated home containing a space exercises
# launcher path resolution. Stub uname, cargo and sesh to check platform selection
# and the actual config passed to sesh without installing packages.

set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd -P)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home space" XDG_CONFIG_HOME="$scratch/config" XDG_CACHE_HOME="$scratch/cache"
mkdir -p "$HOME/.local/bin" "$XDG_CONFIG_HOME/sesh" "$scratch/bin"
export PATH="$scratch/bin:$PATH"

# These files are live symlinks on installed hosts. A merge marker below the
# instant-prompt preamble produces a warning before the first usable prompt.
zsh -n "$repo/.zshrc"
zsh -n "$repo/.alias.zsh"
if grep -nE '^(<<<<<<< |=======($| )|>>>>>>> )' "$repo/.zshrc" "$repo/.alias.zsh"; then
    exit 1
fi

# Exercise the public aliases with an empty home and no private loader.
ln -s "$repo/.alias.zsh" "$HOME/.alias.zsh"
mkdir -p "$HOME/.oh-my-zsh"
touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"
ln -s "$repo/.zshrc" "$HOME/.zshrc"
(
    cd "$repo"
    TMUX=fixture ZDOTDIR="$HOME" zsh -dic '[[ $aliases[gs] == "git status -sb" ]] && gs >/dev/null'
)

printf 'alias fixturework=true\n' > "$HOME/.work.zshrc"
(
    cd "$repo"
    TMUX=fixture ZDOTDIR="$HOME" zsh -dic '[[ $aliases[fixturework] == true ]] && gs >/dev/null'
)

# Exercise the same selection and hooks as the installer without touching the host.
source "$repo/bootstrap.sh"
for os in Darwin Linux; do
    printf '#!/bin/sh\necho %s\n' "$os" >"$scratch/bin/uname"
    chmod +x "$scratch/bin/uname"
    platform=$(host_platform)

    case "$os" in
        Darwin) [ "$platform" = macos ] ;;
        Linux) [ "$platform" = linux ] ;;
    esac
    (
        source "$repo/$platform/bootstrap.sh"
        declare -F prepare_platform finish_platform >/dev/null
    )
done

printf '#!/bin/sh\nprintf "%%s\\n" "$@"\n' >"$scratch/bin/cargo"
chmod +x "$scratch/bin/cargo"
ln -s "$repo/bin/dotfiles" "$scratch/launcher"
ln -s ../../../launcher "$HOME/.local/bin/dotfiles"
"$HOME/.local/bin/dotfiles" audit >"$scratch/args"
grep -Fxq "$repo/dotfiles-cli/Cargo.toml" "$scratch/args"
grep -Fxq audit "$scratch/args"

cp "$repo/sesh/sesh.toml" "$XDG_CONFIG_HOME/sesh/sesh.toml"
cat >"$scratch/bin/sesh" <<'MOCK'
#!/bin/sh
if [ "$1" = -C ]; then
    cat "$2"
else
    echo default
fi
MOCK
chmod +x "$scratch/bin/sesh"
wrapper="$repo/sesh/sesh-wrapper.sh"
[ "$("$wrapper" list)" = default ]
printf '[[session]]\nname = "work"\n' >"$HOME/.work.sesh.toml"
"$wrapper" list >"$scratch/sessions"
grep -q 'name = "dotfiles"' "$scratch/sessions"
grep -q 'name = "work"' "$scratch/sessions"

printf '[default_session]\nstartup_command = "vi"\n' >"$HOME/.work.sesh.toml"
"$wrapper" list >"$scratch/sessions"
cmp "$HOME/.work.sesh.toml" "$scratch/sessions"
