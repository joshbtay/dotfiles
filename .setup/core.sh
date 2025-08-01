# install basic packages
yay --save --answerclean All --answerdiff None
yay -Sy hyprland-meta-git kitty nvim discord blender brightnessctl gimp inkscape ripgrep python-pip pavucontrol openjdk-src zoom walker-bin iwd font-manager feh grim slurp vlc wl-clipboard visual-studio-code-bin fd nodejs krita pulseaudio-ctl firefox zsh github-cli stow swaync

curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

read -n 1 -s -r -p "Log in to "

#ssh
ssh-keygen -t ed25519 -C "joshbtay@gmail.com"
eval `ssh-agent -s`
ssh-add ~/.ssh/id_ed25519

#git
gh auth login

chsh -s /bin/zsh
