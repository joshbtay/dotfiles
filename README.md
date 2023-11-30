<h3>Installation</h3> (Caution: will overwrite many settings!)

```
cd ~/
git init .
git remote add -t \* -f origin https://github.com/joshbtay/dotfiles.git
git checkout master
rm .zshrc .zhistory & git pull origin master --recurse-submodules
./install
```
