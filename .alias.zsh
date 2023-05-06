export EDITOR='nvim'

# editing config
alias ez="$EDITOR ~/.zshrc"       # alias for Edit Zshrc
alias ea="$EDITOR ~/.alias.zsh"   # alias for Edit Alias
alias el="$EDITOR ~/.local.zsh"   # alias for Edit Local
alias sz='exec zsh'               # alias for Source Zsh
alias ewez="cd ~/.config/wezterm && $EDITOR"

alias eh="cd ~/.hammerspoon && $EDITOR"
alias ek="cd ~/.config/karabiner/assets/complex_modifications/ && $EDITOR"
alias eal="cd ~/.config/alacritty && $EDITOR"

alias ex="exa -l -a --grid --git"

# bookmarks
alias @tmp='cd ~/tmp'
alias @downloads='cd ~/Downloads'
alias @repos='cd ~/Documents/repos/'
alias @documents='cd ~/Documents'
alias @pulse='cd ~/Documents/repos/pulse'
alias @tanker='cd ~/Documents/repos/tanker'
alias @lc="cd ~/Documents/repos/leetcode/"
alias @config="cd ~/.config"
alias @dotfiles='cd ~/Documents/repos/dotfiles/'

alias ls='exa -l -a --grid --git'

alias :q='exit'

alias ..='..'
alias ...='../..'
alias ....='../../..'

alias envi="cd ~/.config/nvim && $EDITOR ."

# applications
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcub='docker-compose up --build'

alias v='nvim'
alias y='yarn'
alias m='make'

# create and delete files/folders
alias t='touch'           # create file
alias md='mkdir'          # make directory
alias rd='rm -rf'         # remove directory and file

# misc.
alias q='exit'            # vim like quit command to close terminal pane
alias c='clear'           # clear terminal
alias o='open'            # open file or chrome with full url

# git
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
alias eal="cd ~/.config/alacritty && $EDITOR"

# Git Diff
alias gd='git diff HEAD'

alias bri='brew install'
alias bric='brew install --cask'

#


# cargo
alias cb='cargo build'
