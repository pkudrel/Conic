# PsAutomationHelpers
A few PowerShell scripts that make Build process easier






### Misc notes 
How to marge this repository as a subtree?
from https://help.github.com/articles/about-git-subtree-merges/
https://medium.com/@porteneuve/mastering-git-subtrees-943d29a798ec#.8z199wxmt

```
# init
git remote add -f  ps-auto-helpers https://github.com/pkudrel/PsAutomationHelpers.git
git subtree add  --prefix=src/build --squash ps-auto-helpers master
# to pull
git subtree pull --prefix=src/build ps-auto-helpers master --squash

```

