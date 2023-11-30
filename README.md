<h3>Installation</h3> (Caution: will overwrite many settings!)

```
cd ~/
git init .
git remote add -t \* -f origin https://github.com/joshbtay/dotfiles.git
git checkout master
git branch --set-upstream-to=origin/master master
git submodule init
git submodule update
mv .zshrc .zshrc_backup
git pull --recurse-submodules
./install
```

<h4>To update:</h4>

```
cd ~/
git pull --recurse-submodules
```
