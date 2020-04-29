---
title: "Terminal on MacOS"
---

One of the best terminals for MacOS is [iTerm2](https://www.iterm2.com/).
It has many extra features including better copy/paste support and even
an option for different text color under the cursor. Small things like
this make a big difference.

What if Terminal on MacOS could look and behave more like iTerm2? This
post creates a Terminal profile that mimics the appearance and behavior
of iTerm2, so that the default Terminal can be used in a similar way and
with the same sensible defaults, including:
- Close terminal when process exits (i.e. on `exit`)
- Use option key as `Meta` inside the terminal
- Same title bar with the process name and shortcut key

# Make Terminal look like iTerm2

1. Open Terminal > Preferences... > Profiles > Gear > Import
2. [Download `iTerm.terminal`](/data/2019/iTerm.terminal)
3. Select `iTerm.terminal`. Then select the `iTerm` profile from the
list of profiles to make it active.

Alternatively, copy and paste this plain text into a `iTerm.terminal` file
using a raw text editor like vim or emacs or TextEdit with the plaintext
option turned on in preferences.

> Edit: Removed verbatim plaintext configuration file (April 2020)
