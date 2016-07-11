# PsAutomationHelpers
A few PowerShell scripts that make Build process easier






### Misc notes 
How to marge this repository as a subtree?
(from https://help.github.com/articles/about-git-subtree-merges/)

```
# init
git remote add -f  ps-auto-helpers https://github.com/pkudrel/PsAutomationHelpers.git
git merge -s ours --no-commit  ps-auto-helpers/master
git read-tree --prefix=src/build/ -u ps-auto-helpers/master
git commit -m "Subtree merged"

# update 
git pull -s subtree ps-auto-helpers master
```

