#!/usr/bin/env bash
set -eo pipefail

# =============================================================================
# Dotfiles Bootstrap Script
# Sets up a fresh macOS machine with everything needed for the dev environment.
# Safe to re-run — skips anything already installed.
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$DOTFILES_DIR/bootstrap.log"
FAILURES=0

log()  { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m  OK: %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m  WARN: %s\033[0m\n" "$1"; }
fail() { printf "\033[1;31m  FAIL: %s\033[0m\n" "$1"; }

usage() {
    echo "Usage: ./bootstrap.sh [--check]"
    echo "  --check  Report missing or incorrect setup without making changes"
}

MODE="install"
case "${1:-}" in
    "") ;;
    --check) MODE="check" ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 2
        ;;
esac

if [ "$#" -gt 1 ]; then
    usage
    exit 2
fi

record_failure() {
    fail "$1 — check $LOG_FILE"
    FAILURES=$((FAILURES + 1))
}

ensure_formula() {
    local formula="$1"
    if brew list --formula "$formula" &>/dev/null; then
        ok "$formula"
    else
        log "Installing $formula"
        if brew install "$formula" 2>>"$LOG_FILE"; then
            ok "$formula"
        else
            record_failure "Failed to install $formula"
        fi
    fi
}

cask_app_name() {
    case "$1" in
        wezterm) printf "WezTerm.app" ;;
        ghostty) printf "Ghostty.app" ;;
        hammerspoon) printf "Hammerspoon.app" ;;
        nikitabobko/tap/aerospace) printf "AeroSpace.app" ;;
        raycast) printf "Raycast.app" ;;
        karabiner-elements) printf "Karabiner-Elements.app" ;;
        qmk-toolbox) printf "QMK Toolbox.app" ;;
        firefox) printf "Firefox.app" ;;
    esac
}

cask_installed() {
    local cask="$1" app_name
    app_name="$(cask_app_name "$cask")"

    brew list --cask "$cask" &>/dev/null ||
        { [ -n "$app_name" ] &&
            { [ -d "/Applications/$app_name" ] || [ -d "$HOME/Applications/$app_name" ]; }; }
}

ensure_cask() {
    local cask="$1"

    if cask_installed "$cask"; then
        ok "$cask"
    else
        log "Installing $cask"
        if brew install --cask "$cask" 2>>"$LOG_FILE"; then
            ok "$cask"
        else
            record_failure "Failed to install $cask"
        fi
    fi
}

normalize_git_url() {
    local url="$1"
    case "$url" in
        git@github.com:*) url="https://github.com/${url#git@github.com:}" ;;
        ssh://git@github.com/*) url="https://github.com/${url#ssh://git@github.com/}" ;;
    esac
    printf "%s" "${url%.git}"
}

ensure_git_repo() {
    local name="$1" url="$2" dst="$3" actual_url temp_dir

    if [ -d "$dst/.git" ]; then
        actual_url="$(git -C "$dst" config --get remote.origin.url 2>/dev/null || true)"
        if [ "$(normalize_git_url "$actual_url")" = "$(normalize_git_url "$url")" ]; then
            ok "$name"
        else
            record_failure "$name exists with unexpected origin: $actual_url"
        fi
        return
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        record_failure "$name path exists but is not a valid Git repository: $dst"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bootstrap.XXXXXX")"
    if git clone --depth=1 "$url" "$temp_dir/repo" 2>>"$LOG_FILE" &&
        mv "$temp_dir/repo" "$dst"; then
        ok "$name"
    else
        record_failure "Failed to install $name"
    fi
    rm -rf "$temp_dir"
}

firefox_profile() {
    local profile
    for profile in "$HOME/Library/Application Support/Firefox/Profiles/"*.default-release; do
        if [ -d "$profile" ]; then
            printf "%s" "$profile"
            return
        fi
    done
}

FORMULAE=(
    git
    neovim
    tmux
    fzf
    ripgrep
    fd
    jq
    bat
    tree
    wget
    curl
    coreutils
    zsh
    fastfetch
    thefuck
    eza
    lazygit
    git-delta
    btop
    zoxide
    sesh
    television
    nvm
    python@3
    go
    rustup
    openjdk@21
    kotlin
    bun
    cmake
    make
    blueutil
    FelixKratz/formulae/borders
    FelixKratz/formulae/sketchybar
    kvndrsslr/tap/sketchybar-app-font
    nowplaying-cli
)

CASKS=(
    wezterm
    ghostty
    hammerspoon
    nikitabobko/tap/aerospace
    raycast
    karabiner-elements
    qmk-toolbox
    firefox
)

NERD_FONTS=(
    font-jetbrains-mono-nerd-font
    font-recursive-mono-nerd-font
    font-sf-mono-nerd-font-ligaturized
)

NPM_PACKAGES=(
    typescript
    ts-node
    prettierd
)

TMUX_PLUGINS=(
    vim-tmux-navigator
    tmux-kanagawa
    tmux-sensible
    tmux-resurrect
    tmux-continuum
    tmux-thumbs
    tmux-fzf-url
)

CHECK_FAILURES=0
CHECK_WARNINGS=0

check_failure() {
    fail "$1"
    CHECK_FAILURES=$((CHECK_FAILURES + 1))
}

check_warning() {
    warn "$1"
    CHECK_WARNINGS=$((CHECK_WARNINGS + 1))
}

check_git_repo() {
    local name="$1" url="$2" dst="$3" actual_url

    if [ ! -d "$dst/.git" ]; then
        check_failure "$name is missing or is not a Git repository: $dst"
        return
    fi

    actual_url="$(git -C "$dst" config --get remote.origin.url 2>/dev/null || true)"
    if [ "$(normalize_git_url "$actual_url")" = "$(normalize_git_url "$url")" ]; then
        ok "$name"
    else
        check_failure "$name has unexpected origin: $actual_url"
    fi
}

check_symlink() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        ok "$dst"
    elif [ -e "$dst" ] || [ -L "$dst" ]; then
        check_failure "$dst does not link to $src"
    else
        check_failure "$dst is missing"
    fi
}

check_service() {
    local service="$1" status
    status="$(brew services list 2>/dev/null |
        awk -v service="$service" '$1 == service { print $2; exit }')"
    if [ "$status" = "started" ]; then
        ok "$service service"
    else
        check_failure "$service service is not running"
    fi
}

run_check() {
    local formula cask font package plugin nvm_prefix nvm_script lts_version
    local default_alias npm_bin java_prefix java_source ff_profile ff_chrome
    local go_bin tool zsh_custom

    export HOMEBREW_NO_AUTO_UPDATE=1

    log "Required system tools"
    if xcode-select -p &>/dev/null; then
        ok "Xcode Command Line Tools"
    else
        check_failure "Xcode Command Line Tools are missing"
    fi

    if command -v brew &>/dev/null; then
        ok "Homebrew"
    else
        check_failure "Homebrew is missing"
    fi

    if command -v brew &>/dev/null; then
        log "Homebrew formulae"
        for formula in "${FORMULAE[@]}"; do
            if brew list --formula "$formula" &>/dev/null; then
                ok "$formula"
            else
                check_failure "Missing formula: $formula"
            fi
        done

        log "Homebrew casks"
        for cask in "${CASKS[@]}"; do
            if cask_installed "$cask"; then
                ok "$cask"
            else
                check_failure "Missing cask or application: $cask"
            fi
        done

        log "Nerd Fonts"
        for font in "${NERD_FONTS[@]}"; do
            if cask_installed "$font"; then
                ok "$font"
            else
                check_failure "Missing font cask: $font"
            fi
        done
    fi

    log "Language runtimes"
    if command -v rustc &>/dev/null; then
        ok "Rust $(rustc --version | awk '{print $2}')"
    else
        check_failure "Rust toolchain is missing"
    fi

    export NVM_DIR="$HOME/.nvm"
    nvm_prefix="$(brew --prefix nvm 2>/dev/null || true)"
    nvm_script="$nvm_prefix/nvm.sh"
    if [ -n "$nvm_prefix" ] && [ -s "$nvm_script" ]; then
        source "$nvm_script"
        lts_version="$(nvm version "lts/*" 2>/dev/null || true)"
        if [ -n "$lts_version" ] && [ "$lts_version" != "N/A" ]; then
            ok "Node $lts_version through NVM"
            default_alias=""
            if [ -f "$NVM_DIR/alias/default" ]; then
                default_alias="$(<"$NVM_DIR/alias/default")"
            fi
            if [ "$default_alias" = "lts/*" ]; then
                ok "NVM default alias"
            else
                check_failure "NVM default alias is '$default_alias', expected 'lts/*'"
            fi

            npm_bin="$NVM_DIR/versions/node/$lts_version/bin/npm"
            for package in "${NPM_PACKAGES[@]}"; do
                if [ -x "$npm_bin" ] &&
                    "$npm_bin" list --global --depth=0 "$package" &>/dev/null; then
                    ok "npm: $package"
                else
                    check_failure "Missing global npm package for $lts_version: $package"
                fi
            done
        else
            check_failure "NVM has no installed LTS version"
        fi
    else
        check_failure "NVM is unavailable"
    fi

    if command -v virtualenv &>/dev/null ||
        python3 -m pip show virtualenv &>/dev/null 2>&1; then
        ok "virtualenv"
    else
        check_failure "virtualenv is missing"
    fi

    java_prefix="$(brew --prefix openjdk@21 2>/dev/null || true)"
    java_source="$java_prefix/libexec/openjdk.jdk"
    if [ -n "$java_prefix" ] &&
        [ -L "/Library/Java/JavaVirtualMachines/openjdk-21.jdk" ] &&
        [ "$(readlink "/Library/Java/JavaVirtualMachines/openjdk-21.jdk")" = "$java_source" ]; then
        ok "OpenJDK 21 link"
    else
        check_failure "OpenJDK 21 link is missing or incorrect"
    fi

    log "Managed Git repositories"
    zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    check_git_repo "Oh My Zsh" "https://github.com/ohmyzsh/ohmyzsh.git" "$HOME/.oh-my-zsh"
    check_git_repo "Powerlevel10k" "https://github.com/romkatv/powerlevel10k.git" \
        "$zsh_custom/themes/powerlevel10k"
    check_git_repo "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" \
        "$zsh_custom/plugins/zsh-autosuggestions"
    check_git_repo "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting" \
        "$zsh_custom/plugins/zsh-syntax-highlighting"
    check_git_repo "k" "https://github.com/supercrabtree/k" "$zsh_custom/plugins/k"
    check_git_repo "Tmux Plugin Manager" "https://github.com/tmux-plugins/tpm" \
        "$HOME/.tmux/plugins/tpm"

    log "Managed symlinks"
    check_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    check_symlink "$DOTFILES_DIR/.alias.zsh" "$HOME/.alias.zsh"
    check_symlink "$DOTFILES_DIR/.editorconfig" "$HOME/.editorconfig"
    check_symlink "$DOTFILES_DIR/bin/dotfiles" "$HOME/.local/bin/dotfiles"
    check_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    check_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    check_symlink "$DOTFILES_DIR/wezterm" "$HOME/.config/wezterm"
    check_symlink "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
    check_symlink "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"
    check_symlink "$DOTFILES_DIR/lazygit" "$HOME/.config/lazygit"
    check_symlink "$DOTFILES_DIR/btop" "$HOME/.config/btop"
    check_symlink "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"
    check_symlink "$DOTFILES_DIR/macos/karabiner/karabiner.json" \
        "$HOME/.config/karabiner/karabiner.json"
    check_symlink "$DOTFILES_DIR/macos/.hammerspoon" "$HOME/.hammerspoon"
    check_symlink "$DOTFILES_DIR/macos/.aerospace.toml" "$HOME/.aerospace.toml"
    check_symlink "$DOTFILES_DIR/macos/aerospace-workspace-assign.sh" \
        "$HOME/.config/aerospace-workspace-assign.sh"
    check_symlink "$DOTFILES_DIR/macos/aerospace-toast.sh" \
        "$HOME/.config/aerospace-toast.sh"
    check_symlink "$DOTFILES_DIR/macos/cal-events" "$HOME/.config/cal-events"
    check_symlink "$DOTFILES_DIR/macos/sketchybar" "$HOME/.config/sketchybar"
    check_symlink "$DOTFILES_DIR/macos/borders" "$HOME/.config/borders"

    log "Generated and copied configuration"
    if [ -d "$HOME/.vim/undodir" ]; then
        ok "~/.vim/undodir"
    else
        check_failure "~/.vim/undodir is missing"
    fi

    ff_profile="$(firefox_profile)"
    if [ -n "$ff_profile" ]; then
        ff_chrome="$ff_profile/chrome/userChrome.css"
        if [ -f "$ff_chrome" ] &&
            cmp -s "$DOTFILES_DIR/firefox/userChrome.css" "$ff_chrome"; then
            ok "Firefox userChrome.css"
        else
            check_failure "Firefox userChrome.css is missing or out of date"
        fi
    else
        check_warning "Firefox profile not found; open Firefox once and rerun bootstrap"
    fi

    log "Go tools"
    if command -v go &>/dev/null; then
        go_bin="$(go env GOBIN 2>/dev/null || true)"
        if [ -z "$go_bin" ]; then
            go_bin="$(go env GOPATH 2>/dev/null)/bin"
        fi
        for tool in gopls goimports-reviser golangci-lint; do
            if [ -x "$go_bin/$tool" ]; then
                ok "$tool"
            else
                check_failure "Missing Go tool: $tool"
            fi
        done
    else
        check_failure "Go is unavailable"
    fi

    log "Tmux plugins"
    for plugin in "${TMUX_PLUGINS[@]}"; do
        if [ -d "$HOME/.tmux/plugins/$plugin/.git" ]; then
            ok "$plugin"
        else
            check_failure "Missing tmux plugin: $plugin"
        fi
    done

    if command -v brew &>/dev/null; then
        log "Background services"
        check_service "sketchybar"
        check_service "borders"
    fi

    log "Manual verification"
    if [ -f "$HOME/.p10k.zsh" ]; then
        ok "Powerlevel10k configuration"
    else
        check_warning "Run 'p10k configure' if the prompt is not configured"
    fi
    check_warning "Verify Accessibility access for Hammerspoon and AeroSpace"
    check_warning "Verify Karabiner DriverKit, system extension, and Input Monitoring access"
    check_warning "Verify Firefox userChrome.css is enabled in about:config"
    check_warning "Verify Neovim plugins and Mason language servers after first launch"

    echo ""
    if [ "$CHECK_FAILURES" -gt 0 ]; then
        fail "Setup check found $CHECK_FAILURES issue(s) and $CHECK_WARNINGS manual warning(s)"
        return 1
    fi
    ok "Setup check passed with $CHECK_WARNINGS manual warning(s)"
}

if [ "$MODE" = "check" ]; then
    run_check
    exit $?
fi

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
log "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    ok "Already installed"
else
    xcode-select --install
    echo "Press enter after Xcode CLT installation completes..."
    read -r
fi

# =============================================================================
# 2. Homebrew
# =============================================================================
log "Homebrew"
if command -v brew &>/dev/null; then
    ok "Already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Make sure brew is in PATH for the rest of this script
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

# =============================================================================
# 3. Homebrew Formulae
# =============================================================================
log "Homebrew formulae"

FORMULAE=(
    # Core tools
    git
    neovim
    tmux
    fzf
    ripgrep
    fd
    jq
    bat
    tree
    wget
    curl
    coreutils

    # Shell
    zsh
    fastfetch
    thefuck
    eza
    lazygit
    git-delta
    btop
    zoxide
    sesh
    television

    # Languages & runtimes
    nvm
    python@3
    go
    rustup
    openjdk@21
    kotlin

    # JS/TS
    bun

    # Build tools
    cmake
    make

    # Bluetooth/audio (used by Hammerspoon scripts)
    blueutil

    # Window management / status bar
    FelixKratz/formulae/borders
    FelixKratz/formulae/sketchybar
    kvndrsslr/tap/sketchybar-app-font
    nowplaying-cli
)

for formula in "${FORMULAE[@]}"; do
    ensure_formula "$formula"
done

# =============================================================================
# 4. Homebrew Casks
# =============================================================================
log "Homebrew casks"

CASKS=(
    wezterm
    ghostty
    hammerspoon
    nikitabobko/tap/aerospace
    raycast
    karabiner-elements
    qmk-toolbox
    firefox
)

for cask in "${CASKS[@]}"; do
    ensure_cask "$cask"
done

# =============================================================================
# 5. Nerd Fonts
# =============================================================================
log "Nerd Fonts"
NERD_FONTS=(
    font-jetbrains-mono-nerd-font
    font-recursive-mono-nerd-font
    font-sf-mono-nerd-font-ligaturized
)

for font in "${NERD_FONTS[@]}"; do
    ensure_cask "$font"
done

# =============================================================================
# 6. Rust (via rustup)
# =============================================================================
log "Rust toolchain"
if command -v rustc &>/dev/null; then
    ok "Rust $(rustc --version | awk '{print $2}')"
else
    if command -v rustup-init &>/dev/null &&
        rustup-init -y --no-modify-path 2>>"$LOG_FILE" &&
        [ -s "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
        ok "Rust $(rustc --version | awk '{print $2}')"
    else
        record_failure "Failed to install the Rust toolchain"
    fi
fi

# =============================================================================
# 7. Node.js (via NVM)
# =============================================================================
log "Node.js via NVM"
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
NVM_PREFIX="$(brew --prefix nvm 2>/dev/null || true)"
NVM_SCRIPT="$NVM_PREFIX/nvm.sh"
NODE_READY=false

if [ -n "$NVM_PREFIX" ] && [ -s "$NVM_SCRIPT" ]; then
    source "$NVM_SCRIPT"
    LTS_VERSION="$(nvm version "lts/*" 2>/dev/null || true)"
    if [ -z "$LTS_VERSION" ] || [ "$LTS_VERSION" = "N/A" ]; then
        if nvm install --lts 2>>"$LOG_FILE"; then
            LTS_VERSION="$(nvm version "lts/*" 2>/dev/null || true)"
        else
            record_failure "Failed to install Node.js LTS through NVM"
        fi
    fi

    if [ -n "$LTS_VERSION" ] && [ "$LTS_VERSION" != "N/A" ]; then
        if nvm use --silent "$LTS_VERSION" 2>>"$LOG_FILE"; then
            NODE_READY=true
            ok "Node $(node --version) through NVM"
        else
            record_failure "Failed to activate Node.js $LTS_VERSION through NVM"
        fi

        NVM_DEFAULT_ALIAS=""
        if [ -f "$NVM_DIR/alias/default" ]; then
            NVM_DEFAULT_ALIAS="$(<"$NVM_DIR/alias/default")"
        fi
        if [ "$NVM_DEFAULT_ALIAS" != "lts/*" ] &&
            ! nvm alias default "lts/*" 2>>"$LOG_FILE"; then
            record_failure "Failed to set the default NVM alias"
        fi
    fi
else
    record_failure "NVM is unavailable"
fi

log "Global npm packages"
NPM_PACKAGES=(
    typescript
    ts-node
    prettierd
)

if [ "$NODE_READY" = true ]; then
    for package in "${NPM_PACKAGES[@]}"; do
        if npm list --global --depth=0 "$package" &>/dev/null; then
            ok "$package"
        else
            log "Installing npm package $package"
            if npm install --global "$package" 2>>"$LOG_FILE"; then
                ok "$package"
            else
                record_failure "Failed to install npm package $package"
            fi
        fi
    done
else
    record_failure "Skipped global npm packages because NVM Node.js is unavailable"
fi

# =============================================================================
# 8. Python virtualenv
# =============================================================================
log "Python virtualenv"
if command -v virtualenv &>/dev/null ||
    python3 -m pip show virtualenv &>/dev/null 2>&1; then
    ok "virtualenv already installed"
else
    if python3 -m pip install --user virtualenv 2>>"$LOG_FILE" ||
        python3 -m pip install --break-system-packages virtualenv 2>>"$LOG_FILE"; then
        ok "virtualenv"
    else
        record_failure "Failed to install virtualenv"
    fi
fi

# =============================================================================
# 9. Java symlink
# =============================================================================
log "Java (OpenJDK 21)"
JAVA_LINK="/Library/Java/JavaVirtualMachines/openjdk-21.jdk"
JAVA_PREFIX="$(brew --prefix openjdk@21 2>/dev/null || true)"
JAVA_SOURCE="$JAVA_PREFIX/libexec/openjdk.jdk"
if [ -z "$JAVA_PREFIX" ]; then
    record_failure "OpenJDK 21 is unavailable"
elif [ -L "$JAVA_LINK" ] && [ "$(readlink "$JAVA_LINK")" = "$JAVA_SOURCE" ]; then
    ok "Already linked"
elif [ -e "$JAVA_LINK" ] && [ ! -L "$JAVA_LINK" ]; then
    record_failure "Java destination exists and is not a symlink: $JAVA_LINK"
else
    if sudo ln -sfn "$JAVA_SOURCE" "$JAVA_LINK" 2>>"$LOG_FILE" &&
        [ -L "$JAVA_LINK" ] &&
        [ "$(readlink "$JAVA_LINK")" = "$JAVA_SOURCE" ]; then
        ok "Linked OpenJDK 21"
    else
        record_failure "Failed to link OpenJDK 21"
    fi
fi

# =============================================================================
# 10. Oh My Zsh + Plugins + Theme
# =============================================================================
log "Oh My Zsh"
ensure_git_repo "Oh My Zsh" "https://github.com/ohmyzsh/ohmyzsh.git" "$HOME/.oh-my-zsh"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log "Powerlevel10k theme"
ensure_git_repo "Powerlevel10k" "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM/themes/powerlevel10k"

log "Zsh plugins"

clone_plugin() {
    local plugin="$1" url="$2"
    ensure_git_repo "$plugin" "$url" "$ZSH_CUSTOM/plugins/$plugin"
}

clone_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
clone_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
clone_plugin "k" "https://github.com/supercrabtree/k"

# =============================================================================
# 11. TPM (Tmux Plugin Manager)
# =============================================================================
log "Tmux Plugin Manager"
ensure_git_repo "Tmux Plugin Manager" "https://github.com/tmux-plugins/tpm" \
    "$HOME/.tmux/plugins/tpm"

# =============================================================================
# 12. Symlinks
# =============================================================================
log "Symlinking dotfiles"

symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        ok "$(basename "$dst")"
        return
    fi
    if [ -e "$dst" ]; then
        mv "$dst" "${dst}.bak.$(date +%s)"
        warn "Backed up existing $(basename "$dst")"
    fi
    ln -sf "$src" "$dst"
    ok "Linked $(basename "$dst")"
}

# Shell
symlink "$DOTFILES_DIR/.zshrc"       "$HOME/.zshrc"
symlink "$DOTFILES_DIR/.alias.zsh"   "$HOME/.alias.zsh"

# Global editorconfig (fallback for repos without their own)
symlink "$DOTFILES_DIR/.editorconfig" "$HOME/.editorconfig"
symlink "$DOTFILES_DIR/bin/dotfiles" "$HOME/.local/bin/dotfiles"

# Tmux
symlink "$DOTFILES_DIR/.tmux.conf"   "$HOME/.tmux.conf"

# Neovim
symlink "$DOTFILES_DIR/nvim"         "$HOME/.config/nvim"

# WezTerm
symlink "$DOTFILES_DIR/wezterm"      "$HOME/.config/wezterm"

# Ghostty
symlink "$DOTFILES_DIR/ghostty"      "$HOME/.config/ghostty"

# Fastfetch
symlink "$DOTFILES_DIR/fastfetch"   "$HOME/.config/fastfetch"

# Lazygit
symlink "$DOTFILES_DIR/lazygit"     "$HOME/.config/lazygit"

# Btop
symlink "$DOTFILES_DIR/btop"        "$HOME/.config/btop"

# Sesh (personal config; ~/.work.sesh.toml is gitignored, see sesh/sesh.toml.work.example)
symlink "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"

# Karabiner
symlink "$DOTFILES_DIR/macos/karabiner/karabiner.json" \
    "$HOME/.config/karabiner/karabiner.json"

# Hammerspoon
symlink "$DOTFILES_DIR/macos/.hammerspoon" "$HOME/.hammerspoon"

# AeroSpace
symlink "$DOTFILES_DIR/macos/.aerospace.toml" "$HOME/.aerospace.toml"
symlink "$DOTFILES_DIR/macos/aerospace-workspace-assign.sh" \
    "$HOME/.config/aerospace-workspace-assign.sh"
symlink "$DOTFILES_DIR/macos/aerospace-toast.sh" "$HOME/.config/aerospace-toast.sh"

# Calendar events helper
symlink "$DOTFILES_DIR/macos/cal-events" "$HOME/.config/cal-events"

# Firefox userChrome.css (profile path varies, so copy instead of symlink)
FF_PROFILE=""
for profile in "$HOME/Library/Application Support/Firefox/Profiles/"*.default-release; do
    if [ -d "$profile" ]; then
        FF_PROFILE="$profile"
        break
    fi
done

if [ -n "$FF_PROFILE" ]; then
    mkdir -p "$FF_PROFILE/chrome"
    FF_CHROME="$FF_PROFILE/chrome/userChrome.css"
    if [ -f "$FF_CHROME" ] && cmp -s "$DOTFILES_DIR/firefox/userChrome.css" "$FF_CHROME"; then
        ok "Firefox userChrome.css"
    elif cp "$DOTFILES_DIR/firefox/userChrome.css" "$FF_CHROME"; then
        ok "Updated Firefox userChrome.css"
    else
        record_failure "Failed to update Firefox userChrome.css"
    fi
else
    warn "Firefox profile not found — open Firefox once, then re-run"
fi

# SketchyBar
symlink "$DOTFILES_DIR/macos/sketchybar" "$HOME/.config/sketchybar"

# JankyBorders
symlink "$DOTFILES_DIR/macos/borders" "$HOME/.config/borders"

# =============================================================================
# 13. Neovim undo directory
# =============================================================================
log "Neovim undo directory"
if [ -d "$HOME/.vim/undodir" ]; then
    ok "~/.vim/undodir"
else
    mkdir -p "$HOME/.vim/undodir"
    ok "Created ~/.vim/undodir"
fi

# =============================================================================
# 14. Go tools (needed by nvim go plugins)
# =============================================================================
log "Go tools"
if command -v go &>/dev/null; then
    GO_BIN="$(go env GOBIN)"
    if [ -z "$GO_BIN" ]; then
        GO_BIN="$(go env GOPATH)/bin"
    fi
    export PATH="$GO_BIN:$PATH"

    ensure_go_tool() {
        local binary="$1" module="$2"
        if command -v "$binary" &>/dev/null; then
            ok "$binary"
        else
            log "Installing Go tool $binary"
            if go install "$module@latest" 2>>"$LOG_FILE"; then
                ok "$binary"
            else
                record_failure "Failed to install Go tool $binary"
            fi
        fi
    }

    ensure_go_tool "gopls" "golang.org/x/tools/gopls"
    ensure_go_tool "goimports-reviser" "github.com/incu6us/goimports-reviser/v3"
    ensure_go_tool "golangci-lint" "github.com/golangci/golangci-lint/cmd/golangci-lint"
else
    record_failure "Skipped Go tools because Go is unavailable"
fi

# =============================================================================
# 15. Install tmux plugins
# =============================================================================
log "Tmux plugins"
TMUX_PLUGINS=(
    vim-tmux-navigator
    tmux-kanagawa
    tmux-sensible
    tmux-resurrect
    tmux-continuum
    tmux-thumbs
    tmux-fzf-url
)
MISSING_TMUX_PLUGINS=false
for plugin in "${TMUX_PLUGINS[@]}"; do
    if [ ! -d "$HOME/.tmux/plugins/$plugin/.git" ]; then
        MISSING_TMUX_PLUGINS=true
        break
    fi
done

if [ "$MISSING_TMUX_PLUGINS" = false ]; then
    ok "All tmux plugins already installed"
elif [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ] &&
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>>"$LOG_FILE"; then
    for plugin in "${TMUX_PLUGINS[@]}"; do
        if [ ! -d "$HOME/.tmux/plugins/$plugin/.git" ]; then
            record_failure "Tmux plugin is still missing: $plugin"
        fi
    done
else
    record_failure "Failed to install tmux plugins"
fi

# =============================================================================
# Done
# =============================================================================
if [ "$FAILURES" -gt 0 ]; then
    echo ""
    printf "\033[1;31m========================================\033[0m\n"
    printf "\033[1;31m  Bootstrap completed with %d failure(s)\033[0m\n" "$FAILURES"
    printf "\033[1;31m========================================\033[0m\n"
    echo ""
else
    echo ""
    printf "\033[1;32m========================================\033[0m\n"
    printf "\033[1;32m  Bootstrap complete!\033[0m\n"
    printf "\033[1;32m========================================\033[0m\n"
    echo ""
fi

echo "Remaining manual steps:"
echo "  1. Open a new terminal to load zsh config"
echo "  2. Run 'p10k configure' if Powerlevel10k prompt isn't set up"
echo "  3. Open nvim — Lazy.nvim will auto-install plugins on first launch"
echo "  4. In nvim, run :Mason to verify LSP servers are installed"
echo "  5. Open Karabiner-Elements and add your Dactyl device entry"
echo "     (vendor_id: 17485, product_id: 13623)"
echo "  6. Grant Accessibility permissions to Hammerspoon and AeroSpace"
echo "  7. Start SketchyBar: brew services start sketchybar"
echo "  8. Start Borders: brew services start borders"
echo "  9. Open Firefox once, re-run bootstrap, enable userChrome.css, and restart Firefox"
echo "  See README.md#after-bootstrap for complete setup details"
echo "  Log file: $LOG_FILE"

if [ "$FAILURES" -gt 0 ]; then
    exit 1
fi
