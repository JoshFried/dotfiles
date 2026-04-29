export XDG_CONFIG_HOME="$HOME/.config"

fastfetch
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

export PATH=$PATH:~/go/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    k
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

command -v thefuck &>/dev/null && eval $(thefuck --alias)

source $HOME/.alias.zsh

# Work-specific config (gitignored, only loaded if present)
[[ -f $HOME/.work.zshrc ]] && source $HOME/.work.zshrc

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Added by AIM CLI
export PATH="$HOME/.aim/mcp-servers:$PATH"
