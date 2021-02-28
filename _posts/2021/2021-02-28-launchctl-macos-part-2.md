---
title: "Disabling Auto-Starting Code on macOS"
---

How do you disable auto-launching processes on macOS? In the [previous
post](/2021/02/27/launchctl-macos), we looked at how to discover code
that starts at login and created a bash alias called `help` in order to
quickly check for code that starts automatically. To recap, this boiled
down to three commands:

1. `kextstat | awk '!/ com.apple./{print $6}'`
2. `launchctl list | grep -v '\tcom.apple.'`
3. `ls -a /Library/Launch* ~/Library/Launch*`

In this post, we will examine how to disable the auto-starting processes
(as well as kernel extensions) that these three commands return. Here is
the summary:

1. `sudo kextunload -b com.example.identifier`
2. ``launchctl disable gui/`id -u`/com.example.identifier``
3. `rm -ir /Library/Launch* ~/Library/Launch*`

First, kernel extensions (kexts), which are shown by `kextstat`, can be
removed by running `sudo kextunload -b com.example.identifier` and then
rebooting. [[1],[2]]

Second, processes shown by `launchctl list` can be disabled by running:
``launchctl disable gui/`id -u`/com.example.identifier``. Replacing
`gui` with `user` has the same effect. There are also more `launchctl`
commands to explore. [[3]] To check which identifiers have been
disabled, run: ``launchctl print-disabled gui/`id -u` ``. In order to
not see disabled identifiers in `launchctl list`, reboot.

Disabling an identifier does not guarantee stopping a process from
starting automatically. The `launchctl disable` command does not check
that the identifier is valid --- it just block it. So if there is a typo
in the identifier, the actual process will not be disabled.
Additionally, if an application somehow dynamically changes to use a new
identifier, then disabling the old identifier will not be effective in
stopping the process from auto launching.

Third and finally, many launch files may be located in:
`/Library/LaunchAgents /Library/LaunchDaemons ~/Library/LaunchAgents
~/Library/LaunchDaemons` (this list is not exclusive, they can also
reside elsewhere such as inside of Application bundles themselves).
Although all of these should be able to be manually disabled as
discussed in the second step, they can also just be deleted.  One
command to remove them all is (be careful): `rm -ir /Library/Launch*
~/Library/Launch*`. Sudo may be necessary for removing files in
`/Library/Launch*` depending on the user account priviledges.

Even after removing launch agents or daemons, applications can add them
back again. For example, Chrome will keep adding itself to one of the
`/Library/Launch*` every time Chrome is opened, even if the launch files
are manually deleted each time. One workaround is to use Chrome inside
of a standard user account instead of an admin, so that Chrome does not
have priviledges to write to `/Library`.

[1]: https://osxdaily.com/2015/06/24/load-unload-kernel-extensions-mac-os-x/
[2]: https://developer.apple.com/documentation/apple_silicon/installing_a_custom_kernel_extension
[3]: https://apple.stackexchange.com/questions/29056/launchctl-difference-between-load-and-start-unload-and-stop/308421
