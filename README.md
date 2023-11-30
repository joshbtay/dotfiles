<h3>Installation</h3> (Caution: will overwrite many settings!)

```
cd ~/
git init .
git remote add -t \* -f origin https://github.com/joshbtay/dotfiles.git
git checkout master
mv .zshrc .zshrc_backup
git pull origin master --recurse-submodules
./install
```

<h4>To update:</h4>

```
cd ~/
git submodule update
git pull origin master --recurse-submodules
```
