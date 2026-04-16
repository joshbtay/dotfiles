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
alias lg="lazygit"
alias ld="lazydocker"
alias co="git checkout"
alias ca="add . && commit "
alias ssh="TERM=xterm-256color ssh"
alias pd="pushd"
alias od="popd"
alias ls="ls --color"
alias mm="git fetch origin main:main && git merge origin/main"

export EDITOR=nvim


#### Plugins

source ~/.zplug/init.zsh
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true
zplug romkatv/powerlevel10k, as:theme, depth:1
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions"
zplug "jeffreytse/zsh-vi-mode"
zplug "MichaelAquilina/zsh-you-should-use"
zplug "fdellwing/zsh-bat"
zplug "MichaelAquilina/zsh-auto-notify"
zplug "lukechilds/zsh-nvm"

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
alias zi='vi ~/.zshrc'
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
    co pnpm-lock.yaml || return 1
}
alias wd='git worktree remove --force'
alias oc='opencode'
md() {
    pandoc $1 > /tmp/$1.html
    open /tmp/$1.html
}

# Custom cd function that shows git status when changing between repos
cd() {
    local prev_git_root new_git_root git_status output
    local dest="$@"

    output=$(gtimeout --kill-after=0.1 0.5 bash -c '
        prev_git_root=$(git rev-parse --show-toplevel 2>/dev/null)
        cd '"$dest"' 2>/dev/null || exit 1
        new_git_root=$(git rev-parse --show-toplevel 2>/dev/null)
        [ -z "$new_git_root" ] && exit 0
        [ "$new_git_root" = "$prev_git_root" ] && exit 0
        git_status=$(git status -s)
        if [ -z "$git_status" ]; then
            echo "‧₊˚🧼✩ ₊˚🫧⊹"
        else
            echo "$git_status"
        fi
    ')
    local timeout_exit=$?

    # Always actually cd (the subprocess cd doesn't affect our shell)
    builtin cd "$@" || return $?

    if [ $timeout_exit -eq 124 ]; then
        echo "git status timeout"
    elif [ -n "$output" ]; then
        echo "$output"
    fi
}

alias mm='git fetch origin main && git merge origin/main || vi +DiffviewOpen'
alias rv='acli rovodev tui'
alias rvr='acli rovodev tui --resume'

# check if in git repo, if so, open nvim
gd() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        DIFF="$(git diff HEAD)"
        if [ -z "$DIFF" ]; then
            echo "‧₊˚🧼✩ ₊˚🫧⊹"
            return 0
        fi
        vi +DiffviewOpen
    else
        echo "Not a git repository"
    fi
}

# commenting bc slow
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="/opt/atlassian/bin:$PATH"
export PATH="/opt/atlassian/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-21.jdk/Contents/Home

alias vertigo='$(git rev-parse --show-toplevel)/bin/vertigo'
alias vb='vertigo build'
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

source ~/.afm-git-configrc
