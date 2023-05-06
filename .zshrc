neofetch

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:~/go/bin

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

eval $(thefuck --alias)

source /Users/joshfried/.docker/init-zsh.sh || true # Added by Docker Desktop


source $HOME/.alias.zsh    # load aliases
