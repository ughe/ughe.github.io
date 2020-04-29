---
layout: post
title: "Using Qemu within GDB Part 2"
categories: [gdb, qemu, arm64]
---

In [my previous post]({{ site.baseurl }}{% post_url 2018-08-14-qemu-gdb-integration %}),
I demonstrated a new GDB `qemu` command to automate arm64 Qemu user
space debugging. Although it works seamlessly, it can only handle 7
arguments and is noticeable by the user because one needs to run the
command `qemu a.out 1 2 3 4 5 6 7` (etc...) every time. The goal of
this post is to integrate this command into GDB's default `start` and
`run` commands, so that users will be able to debug arm64 programs
just as easily as x86-64 ones by using the same commands. It also
fixes the arbitrary limit on command line arguments.

# [First Attempt](#first-attempt)

My first attempt relied completely on using GDB's scripting language
([documentation available here](ftp://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_187.html#SEC192)).

Using the logging strategy described here: [https://stackoverflow.com/a/12452235](https://stackoverflow.com/a/12452235),
I was able to get everything working except for the argument passing:

``` bash
define get_target_aarch64
    # Enable Logging
    shell rm -f gdb.log
    set logging file gdb.log
    set logging overwrite on
    set logging redirect on
    set pagination off
    set logging on

    # Get the target and architecture.
    info target

    # Disable Logging
    set logging off
    set pagination on
    set logging redirect off
    set logging overwrite off

    # i.e. `/path/to/the/actual/target/a.out', file type elf64-littleaarch64.
    shell echo 'file '$(grep -o /.*\',\ file\ type gdb.log | sed "s/', file type//g") > gdb.target

    # i.e. `/path/to/the/actual/target/a.out', file type elf64-littleaarch64.
    shell echo -n 'set $aarch64 = 0' > gdb.aarch64
    shell if [[ -n $(grep "file type elf64-.*aarch64." gdb.log) ]]; then echo 1 >> gdb.aarch64; fi
    source gdb.aarch64
    shell rm -f gdb.aarch64 gdb.log
end

define hook-start
  get_target_aarch64
  if ($aarch64)
    target exec true
    qemu
  end
end

define hook-run
  get_target_aarch64
  if ($aarch64)
    echo Running the "start" command. Please use "continue" next.\n
    hook-start
  end
end

define qemu
  shell kill -9 $(ps -u | grep -m 1 'qemu-aarch64 -g 1234' | awk '{print $2}') 2>/dev/null
  # file $target
  source gdb.target
  set logging off
  set logging redirect off
  shell echo Starting Qemu on Port 1234...
  # $(ps -u | grep -m 1 -o '0:00 /bin/true.*' | cut -c 16-) # Tried getting args from ps -u
  shell qemu-aarch64 -g 1234 $(cat gdb.target 2>/dev/null | awk '{print $2}') &>/dev/stdout </dev/stdin &
  target remote :1234
  break main
  continue
  rm -rf gdb.log gdb.aarch64 gdb.target
end
```

While this approach works well, it was very hard to track down all of
the arguments because `show args` does not display them in `hook-start`
and in `hookpost-start` the program will already have crashed if it is
attempting to run an arm64 program natively. I tried lots of methods,
including waiting for the arguments to appear in `ps -u` and grabbing
them from the system logs with a NOP instruction (`target exec true`).
Ultimatley, I decided to try using python to solve the problem.

# [Solution](#solution)

Tom Tromey's posts (including [https://stackoverflow.com/a/17960363](https://stackoverflow.com/a/17960363))
helped a lot in figuring out scripting GDB with Python. There is also
[official documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/Python.html)
available.

By using Python to redefine the start command, I was able to grab the
arguments and pass them to `qemu-aarch64` properly while also
minimizing the amount of logging necessary.

Here is the redefinition of the `start` command in `start.py`:
``` python
### --------------------------------------------------------------------
### start.py
### Author: William Ughetta
### Overrides GDB start command to enable seamless aarch64 debugging.
### Helpful resource: https://stackoverflow.com/a/17960363
### --------------------------------------------------------------------

import subprocess
import re

class StartCommand(gdb.Command):
    """
    Overides the default GDB start command to enable cross-platform aarch64 debugging. Note
    that the "run" command must NOT be changed. Instead, "hook-run" should be defined to
    call this command if the platform is aarch64.
    """
    def __init__ (self):
        super(StartCommand, self).__init__ ("start", gdb.COMMAND_RUNNING, gdb.COMPLETE_NONE)

    def invoke (self, args, from_tty):
        infoTarget = gdb.execute("info target", from_tty, True)
        target = re.search(r"/.*', file type", infoTarget)
        if not target:
            print("No symbol table loaded.  Use the \"file\" command.")
            return
        target = target.group(0)[:-12]

        aarch64 = re.search(r"file type elf64-.*aarch64.", infoTarget)

        if (aarch64):
            try:
                gdb.execute("kill", from_tty, True)
            except:
                pass
            subprocess.call("kill -9 $(ps -u | grep -m 1 'qemu-aarch64 -g 1234' | awk '{print $2}') 2>/dev/null", shell=True)
            gdb.execute("file " + target, from_tty, True)
            print("Startting Qemu on Port 1234: " + target + " " + args)
            subprocess.call("qemu-aarch64 -g 1234 " + target + " " + args + " &>/dev/stdout </dev/stdin &", shell=True)
            gdb.execute("target remote :1234", from_tty, True)
            gdb.execute("break main", from_tty, True)
            gdb.execute("continue", from_tty, True)
            gdb.execute("clear main", from_tty, True)
        else:
            gdb.execute("break main", from_tty, True)
            gdb.execute("run " + args, from_tty)
            gdb.execute("clear main", from_tty, True)

StartCommand()

```

Finally, by creating a `~/.gdbinit`, the `start` command can be
auto-loaded. As the last step, `hook-run` is defined to call the
`start` command if the architecture is `aarch64` (aka arm64). I also
tried having `hook-run` call `continue` after `start`; however, GDB
encounters an error and dumps the core, so `start` is close enough.

Here is `~/.gdbinit`:

``` bash
source start.py

define hook-run
  get_aarch64
  if ($aarch64)
    start
  end
end

define get_aarch64
    # Enable Logging
    shell rm -f gdb.log
    set logging file gdb.log
    set logging overwrite on
    set logging redirect on
    set pagination off
    set logging on

    # Get the target and architecture.
    info target

    # Disable Logging
    set logging off
    set pagination on
    set logging redirect off
    set logging overwrite off

    # i.e. `/path/to/the/actual/target/a.out', file type elf64-littleaarch64.
    shell echo -n 'set $aarch64 = 0' > gdb.aarch64
    shell if [[ -n $(grep "file type elf64-.*aarch64." gdb.log) ]]; then echo 1 >> gdb.aarch64; fi
    source gdb.aarch64
    shell rm -f gdb.aarch64 gdb.log
end

```
