# zmodload zsh/zprof
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



fpath=(~/.local/share/zsh/site-functions $fpath)

#### Case insensitivity
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
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
alias gdiff="DELTA_FEATURES=+side-by-side git diff"
alias di="git -c delta.side-by-side=true diff"
alias vdiff="git difftool HEAD"
alias log="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias cfg="git --git-dir=$HOME/dotfiles/ --work-tree=$HOME"
alias push="git push"
alias pf="push --force-with-lease --no-verify"
alias stash="git stash"
alias lg="lazygit"
alias co="git checkout"
alias us="git restore --staged"

alias ld="lazydocker"
alias ca="add . && commit "
alias can="add . && commit --no-verify "
alias ssh="TERM=xterm-256color ssh"
alias pd="pushd"
alias od="popd"
alias ls="ls --color"
alias h2="npx shopify hydrogen"

export EDITOR=nvim


#### Plugins

source "${HOME}/.local/share/zinit/zinit.git/zinit.zsh"
# export NVM_LAZY_LOAD=true
# export NVM_COMPLETION=true
# This lets shebangs like #!/usr/bin/env node work without loading all of nvm
# export NVM_DIR="$HOME/.nvm"
# export PATH="$NVM_DIR/versions/node/$(cat $NVM_DIR/alias/default)/bin:$PATH"

# Theme — load immediately (needed before first prompt)
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Essential plugins — load immediately
zinit light jeffreytse/zsh-vi-mode
zinit light zsh-users/zsh-autosuggestions

# zsh-system-clipboard rebinds the vi yank/paste/delete widgets by reading the
# current keymap when it loads. zsh-vi-mode (ZVM_INIT_MODE defaults to "last")
# initializes its keymap AFTER .zshrc is sourced, which clobbers those bindings.
# Loading it from zvm_after_init makes the clipboard bindings apply last and win.
# Custom keymap bindings (e.g. ctrl+space) belong here for the same reason.
function zvm_after_init() {
  zinit light kutsan/zsh-system-clipboard

  # ctrl + space to accept autosuggestions
  bindkey -M viins '^ ' autosuggest-accept
  bindkey -M vicmd '^ ' autosuggest-accept
}

# Deferred plugins — load after prompt appears (turbo mode)
zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use
export YSU_IGNORED_ALIASES=("co")

zinit ice wait lucid
zinit light fdellwing/zsh-bat

zinit ice wait lucid
zinit light MichaelAquilina/zsh-auto-notify

# Syntax highlighting should load last
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

# zinit light lukechilds/zsh-nvm

#### ctrl + space to accept autosuggestions is now bound in zvm_after_init
#### above (ZVM resets the keymap on init, so it must be bound after).

#auto notify settings
export AUTO_NOTIFY_THRESHOLD=15
export AUTO_NOTIFY_TITLE="%command finished"
export AUTO_NOTIFY_BODY="%elapsed seconds with exit code %exit_code"
export AUTO_NOTIFY_CANCEL_ON_SIGINT=1
export AUTO_NOTIFY_EXPIRE_TIME=10000

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
PATH="$HOME/scripts:$PATH"
source ~/.env
export ATLASSIAN_MCP_AUTHORIZATION="Basic $(printf '%s:%s' "$ATLASSIAN_EMAIL" "$ATLASSIAN_API_TOKEN" | base64)"
export BITBUCKET_API_TOKEN="${BITBUCKET_API_TOKEN:-$ATLASSIAN_API_TOKEN}"
export SIGNALFX_REALM="${SIGNALFX_REALM:-us1}"
export SPLUNK_TIMEOUT="${SPLUNK_TIMEOUT:-60000}"
# alias pbcopy='wl-copy'
# alias xclip='wl-copy'
alias zi='vi ~/.zshrc'
alias hard='echo "Are you sure? This will delete all uncommitted changes. (y/N)" && read ans && [ "$ans" = "y" ] && git reset --hard && git clean -fd'

y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

typeset -gA WORKTREE_COPY_FILES=(
    [convo-ai]='user-context-for-tests.json'
    [$HOME/atlassian/afm/master]='.env'
)

typeset -gA WORKTREE_POST_CREATE_COMMANDS=(
    [$HOME/atlassian/afm/master]='afm install confluence platform post-office'
)

_realpath() {
    python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

copy_worktree_files() {
    local source_root="$(_realpath "$1")"
    local target_root="$2"
    local repo_name="${source_root:t}"
    local configured_files="${WORKTREE_COPY_FILES[$source_root]:-${WORKTREE_COPY_FILES[$repo_name]}}"

    [ -z "$configured_files" ] && return 0

    local file source_path target_path
    for file in ${(z)configured_files}; do
	source_path="$source_root/$file"
	target_path="$target_root/$file"

	if [ ! -e "$source_path" ]; then
	    echo "Skipping missing worktree copy file: $file" >&2
	    continue
	fi

	mkdir -p "${target_path:h}" || return 1
	cp -a "$source_path" "$target_path" || return 1
    done
}

run_worktree_post_create_commands() {
    local source_root="$(_realpath "$1")"
    local target_root="$2"
    local repo_name="${source_root:t}"
    local configured_commands="${WORKTREE_POST_CREATE_COMMANDS[$source_root]:-${WORKTREE_POST_CREATE_COMMANDS[$repo_name]}}"

    [ -z "$configured_commands" ] && return 0

    (cd "$target_root" && eval "$configured_commands")
}

# add a git worktree, copy configured gitignored files from the main repo
w() {
    # check if there's no first argument or if we're not in a git repo
    if [ -z "$1" ] || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	echo "Usage: w <new-branch-name> [<start-point>] (from a git repo)" >&2
	return 1
    fi

    local branch="$1"
    local start_point="$2"
    local source_root="$(git rev-parse --show-toplevel)"
    local real_source_root="$(_realpath "$source_root")"
    local target_parent="${source_root:h}"

    if [[ "$real_source_root" == "$HOME/atlassian/afm/"* ]]; then
	target_parent="${real_source_root:h}"
    fi

    local target_root="$target_parent/$branch"

    if [ -z "$start_point" ]; then
	if git show-ref --verify --quiet refs/heads/main; then
	    start_point="main"
	elif git show-ref --verify --quiet refs/heads/master; then
	    start_point="master"
	elif git show-ref --verify --quiet refs/remotes/origin/main; then
	    start_point="origin/main"
	elif git show-ref --verify --quiet refs/remotes/origin/master; then
	    start_point="origin/master"
	else
	    echo "Could not find a main or master branch. Pass a start point explicitly." >&2
	    return 1
	fi
    fi

    git worktree add -b "$branch" "$target_root" "$start_point" || return 1

    copy_worktree_files "$source_root" "$target_root" || return 1
    run_worktree_post_create_commands "$source_root" "$target_root" || return 1
    cd "$target_root" || return 1
}
wd() {
    if [ -z "$1" ]; then
	echo "Usage: wd <worktree-path>" >&2
	return 1
    fi

    local worktree_path="$1"
    local branch="$(git -C "$worktree_path" branch --show-current 2>/dev/null)"

    git worktree remove --force "$worktree_path" || return 1

    if [ -n "$branch" ] && git show-ref --verify --quiet "refs/heads/$branch"; then
	git branch -D "$branch"
    fi
}
alias oc='opencode'
md() {
    pandoc $1 > /tmp/$1.html
    open /tmp/$1.html
}

# Custom cd function that shows git status when changing between repos
# cd() {
#     local prev_git_root new_git_root git_status output
#     local dest="$@"
#
#     output=$(gtimeout --kill-after=0.1 0.4 bash -c '
#         prev_git_root=$(git rev-parse --show-toplevel 2>/dev/null)
#         cd '"$dest"' 2>/dev/null || exit 1
#         new_git_root=$(git rev-parse --show-toplevel 2>/dev/null)
#         [ -z "$new_git_root" ] && exit 0
#         [ "$new_git_root" = "$prev_git_root" ] && exit 0
#         git_status=$(git status -s)
#         if [ -z "$git_status" ]; then
#             echo "‧₊˚🧼✩ ₊˚🫧⊹"
#         else
#             echo "$git_status"
#         fi
#     ')
#     local timeout_exit=$?
#
#     # Always actually cd (the subprocess cd doesn't affect our shell)
#     builtin cd "$@" || return $?
#
#     if [ $timeout_exit -eq 124 ]; then
#         echo "git status timeout"
#     elif [ -n "$output" ]; then
#         echo "$output"
#     fi
# }

_find_venv() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/venv/bin/activate" ]]; then
            echo "$dir/venv"
            return 0
        fi
        dir="${dir:h}"
    done
    return 1
}

_auto_venv() {
    local venv
    venv=$(_find_venv)
    if [[ -n "$venv" ]]; then
        if [[ "$VIRTUAL_ENV" != "$venv" ]]; then
            source "$venv/bin/activate"
        fi
    elif [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _auto_venv
_auto_venv

_git_main_branch() {
    if git show-ref --verify --quiet refs/heads/main; then
        echo main
    elif git show-ref --verify --quiet refs/heads/master; then
        echo master
    else
        return 1
    fi
}

mm() {
    local branch
    branch=$(_git_main_branch) || {
        echo "No local main or master branch found"
        return 1
    }

    git fetch origin "$branch" && git merge "origin/$branch" || vi +DiffviewOpen
}

rb() {
    local branch
    branch=$(_git_main_branch) || {
        echo "No local main or master branch found"
        return 1
    }

    git fetch origin "$branch" && git rebase "origin/$branch" || vi +DiffviewOpen
}
alias rv='acli rovodev tui --yolo'
alias rvr='rv --resume'
alias cx='codex --dangerously-bypass-approvals-and-sandbox'
alias cxc='cx resume'
claude() { bash "$HOME/.claude/hooks/append_agents_md.sh"; command claude "$@"; }
alias cl='claude --dangerously-skip-permissions'
alias clc='cl -r'

lport() {
	if [ -z "$1" ]; then
		echo "Usage: lport <port>"
		return 1
	fi
	lsof -i ":$1"
}
kport() {
	if [ -z "$1" ]; then
		echo "Usage: kport <port>"
		return 1
	fi
	kill -9 $(lsof -t -i:"$1")
}
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
# 
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias nvm='fnm'

export PATH="/opt/atlassian/bin:$PATH"
export PATH="/opt/atlassian/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

# fnm is faster than nvm.
# Must be evaluated AFTER the Homebrew PATH export above so fnm's shim dir
# ends up ahead of /opt/homebrew/bin/node (Homebrew has its own node installed).
eval "$(fnm env --use-on-cd --shell zsh)"

export JAVA_HOME=/Library/Java/JavaVirtualMachines/amazon-corretto-21.jdk/Contents/Home
# export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

alias vertigo='$(git rev-parse --show-toplevel)/bin/vertigo'
alias vb='vertigo build'
alias ff='mvn spotless:apply'

alias ignore='git update-index --assume-unchanged'
alias unignore='git update-index --no-assume-unchanged'

# commented bc slow
# export PATH="$HOME/.jenv/bin:$PATH"
# eval "$(jenv init -)"

source ~/.afm-git-configrc

# git-doctor: shell environment configuration
# [ -f "$HOME/.git-doctor/env.sh" ] && source "$HOME/.git-doctor/env.sh"
# if [ -f "$HOME/.afm-bin-path-manager.zsh" ]; then source "$HOME/.afm-bin-path-manager.zsh"; fi
# zprof

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# Added by Teamwork Graph CLI installer
export PATH="/Users/jtaylor11/.local/bin:$PATH"

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# Checkout main, or master if main doesn't exist
cm() {
  if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
  else
    git checkout master
  fi
}



export PATH="$HOME/.rustup/toolchains/stable-aarch64-apple-darwin/bin:$PATH"
