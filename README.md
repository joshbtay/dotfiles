to install, will overwrite settings:
```
cd ~/
git init .
git remote add -t \* -f origin git@github.com:joshbtay/dotfiles.git
git checkout master
git pull --recurse-submodules
./install
```
