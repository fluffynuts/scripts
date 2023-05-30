Resume scripts
---

gentoo suspend/hibernate/resume script docs: https://wiki.gentoo.org/wiki/Elogind#Suspend.2FHibernate_Resume.2FThaw_hook_scripts

TL;DR:

With elogind the situation is much handier. Any suspend/resume and hibernate/thaw hook scripts need to be in the directory /lib64/elogind/system-sleep/ and use the variables $1 (pre or post) and $2 (suspend, hibernate, or hybrid-sleep). For example, in the case of elogind a hook script could have the following format:
FILE /lib64/elogind/system-sleep/example.shAn example of elogind hook

```
#!/bin/bash
case $1/$2 in
  pre/*)
    # Put here any commands expected to be run when suspending or hibernating.
    ;;
  post/*)
    # Put here any commands expected to be run when resuming from suspension or thawing from hibernation.
    ;;
esac
```
