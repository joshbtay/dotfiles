# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


#### HISTORY

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS



#### Case insensitivity
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'


#### Emacs-style controls, so ctrl+r or ctrl+p, etc.
bindkey -e



#### Aliases

alias vi='nvim'
alias py='pypy3'
alias pypy='pypy3'
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias x="exit"

# Git Aliases
alias add="git add"
alias commit="git commit"
alias pull="git pull"
alias stat="git diff --shortstat"
alias status="git status"
alias gdiff="git diff HEAD"
alias vdiff="git difftool HEAD"
alias log="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias cfg="git --git-dir=$HOME/dotfiles/ --work-tree=$HOME"
alias push="git push"
alias stash="git stash"
alias g="lazygit"
alias co="git checkout"
alias ca="git add . && git commit "
alias ssh="TERM=xterm-256color ssh"
alias pd="pushd"
alias od="popd"
alias ls="ls --color"
alias mm="git fetch origin main:main && git merge origin/main"

export EDITOR=nvim



#### Plugins

source ~/.zplug/init.zsh

zplug romkatv/powerlevel10k, as:theme, depth:1
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions"
zplug "jeffreytse/zsh-vi-mode"
zplug "MichaelAquilina/zsh-you-should-use"
zplug "fdellwing/zsh-bat"
zplug "MichaelAquilina/zsh-auto-notify"

#### ctrl + space to accept autosuggestions
bindkey -M viins '^ ' autosuggest-accept
bindkey -M vicmd '^ ' autosuggest-accept

#auto notify settings
export AUTO_NOTIFY_THRESHOLD=15
export AUTO_NOTIFY_TITLE="%command finished"
export AUTO_NOTIFY_BODY="%elapsed seconds with exit code %exit_code"
export AUTO_NOTIFY_CANCEL_ON_SIGINT=1
export AUTO_NOTIFY_EXPIRE_TIME=10000

#### Plugin load

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi


zplug load

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
PATH="/home/josh/scripts:$PATH"
source ~/.env
alias pbcopy='wl-copy'
alias xclip='wl-copy'
alias z='vi ~/.zshrc'
alias i='pnpm install'
alias tc='pnpm type-check'
alias hard='echo "Are you sure? This will delete all uncommitted changes. (y/N)" && read ans && [ "$ans" = "y" ] && git reset --hard && git clean -fd'

y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

y_widget() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    zle push-input
    BUFFER="yazi --cwd-file=\"$tmp\"; [ -f \"$tmp\" ] && cd \"\$(cat \"$tmp\")\" 2>/dev/null; rm -f \"$tmp\""
    zle accept-line
}
zle -N y_widget
bindkey -M viins '^O' y_widget

# add a git worktree, copy the gitignored files from the main repo
w() {
    # check if there's no first argument or if there's no .git directory
    if [ -z "$1" ] || [ ! -d .git ]; then
	echo "Usage: w <new-branch-name> [<start-point>] (from a git repo)" >&2
	return 1
    fi
    local branch="$1"
    local start_point="${2:-main}"
    git worktree add -b "$branch" "../$branch" "$start_point" || return 1
    # no stdout
    rsync -av --progress --exclude '.git' --exclude '.gitignore' --exclude node_modules --exclude '*.log' . "../$branch" 1>/dev/null || return 1
    cd "../$branch" || return 1
    git update-index --skip-worktree packages/scripts/main.ts || return 1
    pnpm install || return 1
}
alias wd='git worktree remove --force'
alias oc='opencode'
alias open='xdg-open'
md() {
    pandoc $1 > /tmp/$1.html
    open /tmp/$1.html
}

# Custom cd function that shows git status when changing between repos
cd() {
    # Get the git root of current directory (if in a git repo)
    local prev_git_root=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        prev_git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    fi
    
    # Actually change directory
    builtin cd "$@"
    local cd_exit_code=$?
    
    # If cd failed, return early
    if [ $cd_exit_code -ne 0 ]; then
        return $cd_exit_code
    fi
    
    # Get the git root of new directory (if in a git repo)
    local new_git_root=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        new_git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    fi
    
    # Show git status if:
    # 1. Moved from non-git to git repo, OR
    # 2. Moved from one git repo to another different git repo
    if [ -n "$new_git_root" ]; then
        if [ -z "$prev_git_root" ] || [ "$prev_git_root" != "$new_git_root" ]; then
            local git_status
            git_status=$(git status -s)
            if [ -z "$git_status" ]; then
                # echo in cyan color
                echo "\033[0;36m‧₊˚🧼✩ ₊˚🫧⊹\033[0m"
            else
                git status -s
            fi
        fi
    fi
    
    return 0
}

mm() {
    git fetch origin main && git merge origin/main || vi +DiffviewOpen
}
