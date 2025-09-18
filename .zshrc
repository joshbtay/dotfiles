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
