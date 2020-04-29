---
title: "Setting up Terminal on MacOS"
---

Setting up convenient Terminal defaults on MacOS can be done manually or
automatically. This post improves upon the [previous post](/2019/04/14/terminal-mac)
by providing a simple `bash` or `zsh` script for setting up useful defaults,
which are to:

- [ ] Disable the bell sound and flash
- [ ] Use option key as the meta key in Terminal
- [ ] Close the window if the shell exits cleanly
- [ ] Enable Secure Keyboard Entry

This can all be done using the `/usr/libexec/PlistBuddy` tool. Here are the
options being changed:

Key | Value | Description
- | - | -
SecureKeyboardEntry | YES |
Bell | NO |
VisualBell | NO
useOptionAsMetaKey | YES |
shellExitAction | 1 | Close if the shell exited cleanly

The `SecureKeyboardEntry` is the only global choice. The other options are
specific to the default theme.

Here is the script: (Note: the last command kills the Terminal app in order to
load the settings)

``` bash
PLIST="$HOME/Library/Preferences/com.apple.Terminal.plist"
THEME=`/usr/libexec/PlistBuddy -c "Print 'Startup Window Settings'" $PLIST`
/usr/libexec/PlistBuddy -c "Set 'SecureKeyboardEntry' YES" $PLIST
/usr/libexec/PlistBuddy -c "Set 'Window Settings':${THEME}:Bell NO" $PLIST
/usr/libexec/PlistBuddy -c "Set 'Window Settings':${THEME}:VisualBell NO" $PLIST
/usr/libexec/PlistBuddy -c "Set 'Window Settings':${THEME}:useOptionAsMetaKey YES" $PLIST
/usr/libexec/PlistBuddy -c "Set 'Window Settings':${THEME}:shellExitAction 1" $PLIST
killall Terminal
```
