#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles Bootstrap Script
# Sets up a fresh macOS machine with everything needed for the dev environment.
# Safe to re-run — skips anything already installed.
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$DOTFILES_DIR/bootstrap.log"

log()  { printf "\033[1;34m==> %s\033[0m\n" "$1"; }
ok()   { printf "\033[1;32m  OK: %s\033[0m\n" "$1"; }
warn() { printf "\033[1;33m  WARN: %s\033[0m\n" "$1"; }
fail() { printf "\033[1;31m  FAIL: %s\033[0m\n" "$1"; }

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
    tree
    wget
    curl
    coreutils

    # Shell
    zsh
    neofetch
    thefuck
    exa
    lazygit

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
    nowplaying-cli

    # QMK
    qmk-toolbox
)

for formula in "${FORMULAE[@]}"; do
    if brew list "$formula" &>/dev/null; then
        ok "$formula"
    else
        log "Installing $formula"
        brew install "$formula" 2>>"$LOG_FILE" || warn "Failed to install $formula — check $LOG_FILE"
    fi
done

# =============================================================================
# 4. Homebrew Casks
# =============================================================================
log "Homebrew casks"

CASKS=(
    wezterm
    ghostty
    hammerspoon
    amethyst
    raycast
    karabiner-elements
    qmk-toolbox
)

for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        ok "$cask"
    else
        log "Installing $cask"
        brew install --cask "$cask" 2>>"$LOG_FILE" || warn "Failed to install $cask — check $LOG_FILE"
    fi
done

# =============================================================================
# 5. Nerd Fonts (all of them)
# =============================================================================
log "Nerd Fonts"
if brew tap | grep -q "homebrew/cask-fonts" 2>/dev/null; then
    ok "Font tap already added"
fi

# Install all nerd fonts available via homebrew
NERD_FONTS=$(brew search --cask '/font-.*-nerd-font/' 2>/dev/null | grep "nerd-font" || true)
FONT_COUNT=$(echo "$NERD_FONTS" | wc -l | tr -d ' ')
log "Found $FONT_COUNT nerd fonts to install"

INSTALLED=0
SKIPPED=0
for font in $NERD_FONTS; do
    if brew list --cask "$font" &>/dev/null; then
        SKIPPED=$((SKIPPED + 1))
    else
        brew install --cask "$font" 2>>"$LOG_FILE" || warn "Failed to install $font"
        INSTALLED=$((INSTALLED + 1))
    fi
done
ok "Nerd fonts: $INSTALLED installed, $SKIPPED already present"

# =============================================================================
# 6. Rust (via rustup)
# =============================================================================
log "Rust toolchain"
if command -v rustc &>/dev/null; then
    ok "Rust $(rustc --version | awk '{print $2}')"
else
    rustup-init -y --no-modify-path
    source "$HOME/.cargo/env"
fi

# =============================================================================
# 7. Node.js (via NVM)
# =============================================================================
log "Node.js via NVM"
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"

if command -v node &>/dev/null; then
    ok "Node $(node --version)"
else
    nvm install --lts
    nvm use --lts
    nvm alias default node
fi

# Install global npm packages
log "Global npm packages"
npm install -g typescript ts-node prettierd 2>>"$LOG_FILE" || warn "npm globals failed"

# =============================================================================
# 8. Python virtualenv
# =============================================================================
log "Python virtualenv"
if python3 -m pip show virtualenv &>/dev/null 2>&1; then
    ok "virtualenv already installed"
else
    python3 -m pip install --user virtualenv 2>>"$LOG_FILE" || \
    python3 -m pip install --break-system-packages virtualenv 2>>"$LOG_FILE" || \
    warn "virtualenv install failed — may need pipx"
fi

# =============================================================================
# 9. Java symlink
# =============================================================================
log "Java (OpenJDK 21)"
JAVA_HOME_TARGET="/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home"
if [ -d "$JAVA_HOME_TARGET" ]; then
    ok "Already linked"
else
    sudo ln -sfn "$(brew --prefix openjdk@21)/libexec/openjdk.jdk" \
        /Library/Java/JavaVirtualMachines/openjdk-21.jdk 2>/dev/null || \
    warn "Java symlink failed — may need sudo"
fi

# =============================================================================
# 10. Oh My Zsh + Plugins + Theme
# =============================================================================
log "Oh My Zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "Already installed"
else
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log "Powerlevel10k theme"
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    ok "Already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$ZSH_CUSTOM/themes/powerlevel10k"
fi

log "Zsh plugins"
declare -A ZSH_PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [k]="https://github.com/supercrabtree/k"
)

for plugin in "${!ZSH_PLUGINS[@]}"; do
    if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
        ok "$plugin"
    else
        git clone --depth=1 "${ZSH_PLUGINS[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin"
    fi
done

# =============================================================================
# 11. TPM (Tmux Plugin Manager)
# =============================================================================
log "Tmux Plugin Manager"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    ok "Already installed"
else
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

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

# Tmux
symlink "$DOTFILES_DIR/.tmux.conf"   "$HOME/.tmux.conf"

# Neovim
symlink "$DOTFILES_DIR/nvim"         "$HOME/.config/nvim"

# WezTerm
symlink "$DOTFILES_DIR/wezterm"      "$HOME/.config/wezterm"

# Karabiner
symlink "$DOTFILES_DIR/macos/karabiner" "$HOME/.config/karabiner"

# Hammerspoon
symlink "$DOTFILES_DIR/macos/.hammerspoon" "$HOME/.hammerspoon"

# Amethyst
symlink "$DOTFILES_DIR/macos/.amethyst.yml" "$HOME/.amethyst.yml"

# SketchyBar
symlink "$DOTFILES_DIR/macos/sketchybar" "$HOME/.config/sketchybar"

# JankyBorders
symlink "$DOTFILES_DIR/macos/borders" "$HOME/.config/borders"

# =============================================================================
# 13. Neovim undo directory
# =============================================================================
log "Neovim undo directory"
mkdir -p "$HOME/.vim/undodir"
ok "Created ~/.vim/undodir"

# =============================================================================
# 14. Go tools (needed by nvim go plugins)
# =============================================================================
log "Go tools"
if command -v go &>/dev/null; then
    go install golang.org/x/tools/gopls@latest 2>>"$LOG_FILE" || warn "gopls install failed"
    go install github.com/incu6us/goimports-reviser/v3@latest 2>>"$LOG_FILE" || warn "goimports-reviser install failed"
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest 2>>"$LOG_FILE" || warn "golangci-lint install failed"
    ok "Go tools installed"
else
    warn "Go not found — skipping Go tools"
fi

# =============================================================================
# 15. Install tmux plugins
# =============================================================================
log "Tmux plugins"
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>>"$LOG_FILE" || warn "Tmux plugin install failed"
    ok "Tmux plugins installed"
else
    warn "TPM not ready — run prefix+I in tmux to install plugins"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
printf "\033[1;32m========================================\033[0m\n"
printf "\033[1;32m  Bootstrap complete!\033[0m\n"
printf "\033[1;32m========================================\033[0m\n"
echo ""
echo "Remaining manual steps:"
echo "  1. Open a new terminal to load zsh config"
echo "  2. Run 'p10k configure' if Powerlevel10k prompt isn't set up"
echo "  3. Open tmux and press prefix+I to install tmux plugins"
echo "  4. Open nvim — Lazy.nvim will auto-install plugins on first launch"
echo "  5. In nvim, run :Mason to verify LSP servers are installed"
echo "  6. Open Karabiner-Elements and add your Dactyl device entry"
echo "     (vendor_id: 17485, product_id: 13623)"
echo "  7. Grant Accessibility permissions to Hammerspoon and Amethyst"
echo "  8. Start SketchyBar and Borders: brew services start borders sketchybar"
echo "  9. Log file: $LOG_FILE"
