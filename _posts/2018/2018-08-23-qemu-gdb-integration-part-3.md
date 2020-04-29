---
title: "Using Qemu within GDB Part 3"
---

# Summary

This third post is the ~~final~~ follow-up on the series of posts
investigating how to overload GDB's `start` and `run` commands to
automatically debug aarch64 binaries using Qemu's user-space emulation
mode. In [Part 2](/2018/08/20/qemu-gdb-integration-part-2), I overloaded the `start` command and just redirected the `run`
command to basically perform a `start`, leaving the user to finish it
with the `continue` command.

# Run

The final stretch in completing the commands was to also make `run`
work. While at it, it this post combines the previous `start.py` and
`~/.gdbinit` files into one file (now just `~/.gdbinit`), using an
approach detailed [on stackoverflow](https://stackoverflow.com/a/15032459).

To actually get `run` to work, the largest hurdle is preventing GDB
from crashing, which would happen if a `continue` is added. For
whatever reason, this extra continue does NOT cause GDB to crash if
it is in a `start` command (meaning the user typed `start` or `run`).
The crash seams to be related to a GDB check that thinks it is on an
x86-64 system, when in fact it has just connected to the Qemu emulator
running aarch64 code. To resolve this, I have Python raise an exception,
which stop GDB from continuing the rest of its `run` code. The program
has already run, and the only output that is printed is a short Python
message. This can be redirected when starting GDB to `/dev/null` if it
is particularly bothersome, although it is possible that that would also
redirect other important messages.

The Python-defined `start` command is able to tell if it is being called
by the user or by the `hook-run` preface to the `run` command by
checking for a temporary file called `.tmp.gdb.isRun`, in the current
directory. If this file exists, then the user first called `run`, which
determined the binary type was aarch64. Otherwise, the user just called
`start` directly.

# The Code

The below `~/.gdbinit` file contains everything needed to overload `run`
and `start` to work with Qemu:

``` python
### --------------------------------------------------------------------
### .gdbinit
### Author: William Ughetta
###
### Overloads `start` and `run` commands to debug aarch64 binaries
### with Qemu user-space emulation on port 1234.
###
### Helpful resources:
### https://gist.github.com/nojhan/c3bc28e2fa0608f21551
### https://stackoverflow.com/a/17960363
### https://stackoverflow.com/a/12452235
### https://stackoverflow.com/a/15032459
### --------------------------------------------------------------------

define hook-run
  get_aarch64
  if ($aarch64)
    shell touch .tmp.gdb.isRun
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

    # i.e. `/path/to/a.out', file type elf64-littleaarch64.
    shell echo -n 'set $aarch64 = 0' > gdb.aarch64
    shell if [[ -n $(grep "file type elf64-.*aarch64." gdb.log) ]]; \
        then echo 1 >> gdb.aarch64; fi
    source gdb.aarch64
    shell rm -f gdb.aarch64 gdb.log
end

python
### --------------------------------------------------------------------
### start.py
### Author: William Ughetta
### Overrides GDB start command to enable seamless aarch64 debugging.
### --------------------------------------------------------------------

import os.path
import re
import subprocess

class StartCommand(gdb.Command):
    """
    Overides the default GDB start command to enable cross-platform
    aarch64 debugging. Note that the "run" command must NOT be changed.
    Instead, "hook-run" should be defined to call this command if the
    platform is aarch64.
    """
    def __init__ (self):
        super(StartCommand, self).__init__("start",
          gdb.COMMAND_RUNNING, gdb.COMPLETE_NONE)

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
            subprocess.call("kill -9 $(ps -u | grep -m 1 " +
                "'qemu-aarch64 -g 1234' | " +
                "awk '{print $2}') 2>/dev/null", shell=True)
            gdb.execute("file " + target, from_tty, True)
            print("Starting Qemu on Port 1234: " + target + " " + args)
            subprocess.call("qemu-aarch64 -g 1234 " + target + " " +
                args + " &>/dev/stdout </dev/stdin &", shell=True)
            gdb.execute("target remote :1234", from_tty, True)
            # Execute the `run` command or the `start` command
            isRun = os.path.isfile(".tmp.gdb.isRun")
            if (isRun): # `run`
                gdb.execute("continue", from_tty, True)
                subprocess.call("rm -f " + ".tmp.gdb.isRun", shell=True)
                raise Exception("[Inferior 1 (Remote target) exited " +
                    "normally]")
            else:       # `start`
                gdb.execute("break main", from_tty, True)
                gdb.execute("continue", from_tty, True)
                gdb.execute("clear main", from_tty, True)
        else:
            gdb.execute("break main", from_tty, True)
            gdb.execute("run " + args, from_tty)
            gdb.execute("clear main", from_tty, True)

StartCommand()

end

```

# Sample Execution

The following execution examples were started with a `hello.s` program
in `a.out` (compiled with `aarch64-linux-gnu-gcc -static -g hello.s`)
and run with `gdb-multiarch a.out`.

The `start` command with an aarch64 binary:

```
(gdb) start
Starting Qemu on Port 1234: /home/vagrant/workspace/a.out
0x00000000004003f0 in _start ()

Breakpoint 1, main () at hello.s:6
6   stp x29, x30, [sp, #-16]!
(gdb) c
Continuing.
hello, world
[Inferior 1 (Remote target) exited normally]
(gdb)
```

The `run` command with an aarch64 binary:

```
(gdb) run
Starting Qemu on Port 1234: /home/vagrant/workspace/a.out
0x00000000004003f0 in _start ()
hello, world
[Inferior 1 (Remote target) exited normally]
Python Exception <class 'Exception'> [Inferior 1 (Remote target) exited normally]:
Error occurred in Python command: [Inferior 1 (Remote target) exited normally]
(gdb)
```

Mix of two `start`'s and on `run` command on aarch64:

```
(gdb) start
Starting Qemu on Port 1234: /home/vagrant/workspace/a.out
0x00000000004003f0 in _start ()

Breakpoint 7, main () at hello.s:6
6   stp x29, x30, [sp, #-16]!
(gdb) n
8   adr x0, cMes
(gdb)
9   bl  printf
(gdb)
hello, world
11    mov w0, #0
(gdb) start

QEMU: Terminated via GDBstub
Starting Qemu on Port 1234: /home/vagrant/workspace/a.out
0x00000000004003f0 in _start ()

Breakpoint 8, main () at hello.s:6
6   stp x29, x30, [sp, #-16]!
(gdb) run

QEMU: Terminated via GDBstub
Starting Qemu on Port 1234: /home/vagrant/workspace/a.out
0x00000000004003f0 in _start ()
hello, world
[Inferior 1 (Remote target) exited normally]
Python Exception <class 'Exception'> [Inferior 1 (Remote target) exited normally]:
Error occurred in Python command: [Inferior 1 (Remote target) exited normally]
(gdb)
```

Note that while this also behaves normally with x86-64, the debugging
session should be quit before switching between binary types. Running
`start` or `run` on aarch64 and then x86-64 immediatley (or vice-versa)
will not work.
