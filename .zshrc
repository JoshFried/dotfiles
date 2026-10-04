export XDG_CONFIG_HOME="$HOME/.config"

if (( $+commands[brew] )); then
  eval "$(brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  openjdk_prefix="$HOMEBREW_PREFIX/opt/openjdk@21"
  for java_home in \
    "$openjdk_prefix/libexec/openjdk.jdk/Contents/Home" \
    "$openjdk_prefix/libexec/openjdk.jdk" \
    "$openjdk_prefix"; do
    if [[ -x "$java_home/bin/java" ]]; then
      export JAVA_HOME="$java_home"
      export PATH="$JAVA_HOME/bin:$PATH"
      break
    fi
  done
  unset openjdk_prefix java_home
fi

[[ -z "${TMUX:-}" ]] && command -v fastfetch &>/dev/null && fastfetch
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

export PATH="$HOME/.toolbox/bin:$PATH:$HOME/go/bin:$HOME/.local/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting
)

[[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/k" ]] && plugins+=(k)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if command -v thefuck &>/dev/null; then
  fuck() {
    local corrected_command
    corrected_command="$(
      TF_SHELL=zsh \
        TF_ALIAS=fuck \
        TF_SHELL_ALIASES="$(alias)" \
        TF_HISTORY="$(fc -ln -10)" \
        PYTHONIOENCODING=utf-8 \
        thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@"
    )" || return
    eval "$corrected_command"
    [[ -n "$corrected_command" ]] && print -s "$corrected_command"
  }
fi

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

# zoxide — smarter cd (used by sesh for directory history)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Alt-s: fuzzy-pick a sesh session (works in/out of tmux)
sesh-sessions() {
  local session
  session=$(sesh list -i | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
  [[ -z "$session" ]] && zle reset-prompt && return
  BUFFER="sesh connect \"$session\""
  zle accept-line
}
zle -N sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

if [[ -x "$HOME/.config/cal-events" ]]; then
  "$HOME/.config/cal-events" > /tmp/cal-events.txt 2>/dev/null &!
fi
