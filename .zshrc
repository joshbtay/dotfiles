# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Use powerline
USE_POWERLINE="true"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi
alias vim='nvim'
alias vi='nvim'
alias py='pypy3'
alias pypy='pypy3'
#source /usr/share/nvm/init-nvm.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/etc/profile.d/conda.sh" ]; then
        . "/usr/etc/profile.d/conda.sh"
    else
        export PATH="/usr/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
alias bat="cat /sys/class/power_supply/BAT0/capacity"
alias vol="pamixer --get-volume"
function pt {
        [ ! -d "~/code/comp/$1/" ] && mkdir ~/code/comp/$1
        cd ~/code/comp/$1
        ~/code/comp/pt $1
}
function ct {
        [ ! -d "~/code/comp/$1/" ] && mkdir ~/code/comp/$1
        cd ~/code/comp/$1
        ~/code/comp/ct $1
}
function aoc {
        [ ! -d "~/code/comp/aoc$1/" ] && mkdir ~/code/comp/aoc$1
        cd ~/code/comp/aoc$1
        ~/code/comp/aoc aoc$1
}

passoff () {
        python ~/code/kattis/passoff $1
}

pass () {
        python ~/code/kattis/pass $1
}

run () {
	python ~/code/kattis/run $1
}

p () {
	python ~/code/kattis/p $1
}

crun () {
        if g++ ./run.cpp -o run; then
                python ~/code/kattis/crun $1
        fi
}

function submit {
        ~/code/kattis/submit
}
function pub {
        ~/code/kattis/pub
}
function kattis {
        [ ! -d "~/code/kattis/$1/" ] && mkdir ~/code/kattis/$1
        cd ~/code/kattis/$1
        ~/code/kattis/kattis $1
}
function cattis {
        [ ! -d "~/code/kattis/$1/" ] && mkdir ~/code/kattis/$1
        cd ~/code/kattis/$1
        ~/code/kattis/cattis $1
}

export EDITOR=nvim

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

source /etc/profile.d/vte.sh
PATH=$PATH:~/.local/bin
export LD_LIBRARY_PATH=$PWD/lib:$LD_LIBRARY_PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/taylor/lib/google-cloud-sdk/path.zsh.inc' ]; then . '/home/taylor/lib/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/taylor/lib/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/taylor/lib/google-cloud-sdk/completion.zsh.inc'; fi

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
