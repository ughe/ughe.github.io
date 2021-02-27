---
title: "Checking for Auto-Starting Code on macOS"
---

Applications and processes can start automatically on login on macOS,
and there are a number of different ways to enable or disable
auto-launching code. For example, a user could check for apps in `System
Preferences > Users & Groups > Login Items`. However, this does not show
all auto-starting code. Even popular apps, such as Spotify, [[1]] might not
appear in System Preferences. Another idea is to check the common
directories `/Library/Launch* ~/Library/Launch*`; however, these are not
guaranteed to contain the auto-launching code either. [[2]]

Check for auto-launching code on macOS by running `launchctl list`, for
example:

```bash
launchctl list | grep -v '\tcom.apple.'
```

Even though the command above filters out code identified with Apple
(`com.apple.`), some results may still be core macOS code. Note that
some identifiers may be prefixed with `application`, and these should
probably be ignored. Check for macOS code that does not have a
`com.apple.*` identifier, by searching the `/System/Library/Launch*`
directories---which are part of macOS and protected by [System Integrity
Protection (SIP)](https://support.apple.com/en-us/HT204899)---as
follows:

```bash
ls -a /System/Library/Launch* | grep -v '^com.apple.'
```

If a service shown using the `launchctl list` command---let's say it is
called `com.example.launch-service`---is not a macOS service and should
be disabled, then run the following command to prevent it from launching
on the next login:

```bash
launchctl disable gui/`id -u`/com.example.launch-service
```

In order to see the full list of disabled services, [[3]] run:

```bash
launchctl print-disabled user/`id -u`
```
<!-- db file may be in: ```cat /var/db/com.apple.xpc.launchd/disabled.`id -u`.plist``` -->

For more information on using `launchctl` on macOS, there is a blog post
by Babo D called "LAUNCHCTL 2.0 SYNTAX" from 2016. [[4]] In addition to
seeing code that starts automatically, it may also be interesting to
inspect the kernel extensions that have been loaded using the
`kextstat`.

Putting this all together, a bash alias called `help` combines all of
these steps in order to quickly check for auto-launching code (as well
as kernel extensions):

```bash
alias help="\
kextstat | awk '!/ com.apple./{print $6}' ; \
echo 'usage: launchctl disable gui/\`id -u\`/com.example.launch-service' ; \
launchctl list | grep -v '\tcom.apple.' ; \
ls -a /Library/Launch* ~/Library/Launch* "
```

[1]: https://apple.stackexchange.com/questions/325181/how-to-prevent-app-from-auto-starting
[2]: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLoginItems.html
[3]: https://developer.apple.com/forums/thread/8489
[4]: https://babodee.wordpress.com/2016/04/09/launchctl-2-0-syntax/
