export EDITOR='nvim'

alias zel="zellij -l compact"


# editing config
alias ez="$EDITOR ~/.zshrc"       # alias for Edit Zshrc
alias ea="$EDITOR ~/.alias.zsh"   # alias for Edit Alias
alias ew="$EDITOR ~/.work.alias.zsh"
alias el="$EDITOR ~/.local.zsh"   # alias for Edit Local
alias sz='exec zsh'               # alias for Source Zsh

alias brew="/opt/homebrew/bin/brew"

alias eh="cd ~/.hammerspoon && $EDITOR"
alias ek="cd ~/.config/karabiner/assets/complex_modifications/ && $EDITOR"
alias ewez="cd ~/.config/wezterm/ && $EDITOR"
alias eg="cd ~/.config/ghostty && $EDITOR" 

alias :q="exit"

alias ls='eza -l -a --grid --git'
alias vguard='@guard && v .'

# sesh — auto-pass -C to work config when present
# (keeps personal sesh.toml as default; work file is gitignored)
if [[ -f "$HOME/.work.sesh.toml" ]]; then
    sesh() { command sesh -C "$HOME/.work.sesh.toml" "$@"; }
fi

# Tmux-aware project bookmarks: inside tmux, connect via sesh (named session +
# startup command from sesh.toml); outside tmux, plain cd. Plain directory
# bookmarks (Downloads, Documents, etc.) stay as aliases further down.
# Note: 'dir' not 'path' — $path is a special zsh array tied to $PATH.
_sesh_or_cd() {
    local name="$1" dir="$2"
    if [[ -n "$TMUX" ]] && command -v sesh &>/dev/null; then
        sesh connect "$name"
    else
        cd "$dir"
    fi
}

# Personal project bookmarks
@dotfiles() { _sesh_or_cd dotfiles ~/repos/dotfiles; }
@nvim-config() { _sesh_or_cd nvim-config ~/.config/nvim; }

# Plain directory bookmarks (no session semantics needed)
alias @tmp='cd ~/tmp'
alias @downloads='cd ~/Downloads'
alias @repos='cd ~/repos/'
alias @documents='cd ~/Documents'
alias @config='cd ~/.config'
alias @pics='cd ~/Pictures'

alias ..='..'
alias ...='../..'
alias ....='../../..'

alias envi="cd ~/.config/nvim && $EDITOR"
alias eal="cd ~/.config/alacritty/ && $EDITOR"

# applications
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcub='docker-compose up --build'
alias y='yarn'
alias m='make'
alias v='nvim'
alias nvim="/opt/homebrew/bin/nvim"

# create and delete files/folders
alias t='touch'           # create file
alias md='mkdir'          # make directory
alias rd='rm -rf'         # remove directory and file
 
# misc.
alias c='clear'           # clear terminal
alias o='open'            # open file or chrome with full url

# git
alias lg='lazygit'
alias g='git'
  
# Commit Management
alias ga='git add'
alias gu='git unadd'                      # git config --global alias.unadd reset HEAD
alias grb='git rebase'
alias gcp='git cherry-pick'
alias gca='git commit -v --amend'
alias gmsg='git commit -m'
alias gempty="git commit --allow-empty -m 'empty'"
  
# Branch Management
alias gb='git branch'                     # make _git_push_auto_branch_local
alias gr='git remote -v'
alias gf='git fetch'
alias gfa='git fetch --all'
  
alias gco='git checkout'
alias gnew="git checkout -b"
alias gp='git push'
alias gprune="git remote prune origin | grep -o '\[pruned\] origin\/.*$' | sed -e 's/\[pruned\] origin\///' | xargs git branch -D"
  
# Experimental
alias gpop='git reset --soft head^ && git unadd :/'        
alias gsave='git add :/ && git commit -m "save point"'
  
# Git Status
alias gs='git status -sb'           # short and concise
  
# Git Log
alias gl='_git_commit_all'          # show all commits (from cb-zsh)
alias gll='git log --stat'          # git log with file info
alias glll='git log --stat -p'      # git log with file info + content
  
# Git Commits
alias glc='_git_commit_diff'        # show commits diff against (upstream|origin)/master (from cb-zsh)
  
# Git Diff
alias gd='git diff HEAD'

alias bri='brew install'
alias bric='brew install --cask'

# cargo 
alias cb='cargo build'
alias ct='cargo nextest run'
alias cn='cargo +nightly'

alias gityeet="git clean -fd"

copy() {
    cat "$1" | pbcopy
}
