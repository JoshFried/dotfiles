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

alias :q="exit"

alias ls='exa -l -a --grid --git'
alias vguard='@guard && v .'

# bookmarks
alias @tmp='cd ~/tmp'
alias @downloads='cd ~/Downloads'
alias @repos='cd ~/repos/'
alias @documents='cd ~/Documents'
alias @guard='cd ~/repos/cloudformation-guard'
alias @dotfiles='cd ~/repos/dotfiles/'
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
# alias nvim="/opt/homebrew/bin/nvim"

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
alias gp='git push'       # git push to origin on current branch if no argument specified. Otherwise, git push to specified remote. (from cb-zsh)
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
alias ct='cargo test'

function wezterm(){
    # NOTE: not sure why this isnt working rn
    # op="$(awk -F= '/^NAME/{print $2}' /etc/os-release)"

    op="$(uname -s)"
    case $op in 
    Linux)
        echo "FKDJSLKJFLKDSJF"
        flatpak run org.wezfurlong.wezterm
        ;;
    *)
        ;;
    esac

}

function keys() {
    xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
}
