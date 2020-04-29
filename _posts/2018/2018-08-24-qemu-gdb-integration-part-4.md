---
title: "Using Qemu within GDB Part 4"
---

In the [previous post](/2018/08/23/qemu-gdb-integration-part-3),
all of the commands were condensed into a single `~/.gdbinit` file and
`start` and `run` were overloaded to work with Qemu. However, there was
a subtle-bug: the `run` command did not pass arguments because it never
had them in the first place (as it was really `hook-run`). In order
to fix this, the `hook-run` command needed to obtain the arguments
without overriding the `run` command.

# Possible Approaches

While this could have been fixed with a patch to GDB sending command
arguments also to their hooks in the methods `execute_cmd_pre_hook` in
the source file `gdb/gdb/cli/cli-script.c` and where it is called in the
`execute_command` function in `gdb/gdb/top.c`, it is would require a
more significant change. Another approach is to get the arguments
directly from the user input. This could be done using
`gdb-multiarch | tee .tmp.gdb.log`, although it would not be a clean
solution because it does not all fit inside `~/.gdbinit`. A similar
method would be to turn on `set trace-commands on` as discussed [here](https://stackoverflow.com/q/25195501); however, this introduces too much garbage stdout messages.
It [turns out](https://sourceware.org/gdb/onlinedocs/gdb/Command-History.html)
there is actually a command called `show commands`, which lists the
most recent commands, and this enables the `~/.gdbinit` to obtain the
`start` command's arguments.

# .gdbinit

``` python
### --------------------------------------------------------------------
### .gdbinit
### Author: William Ughetta
### Overloads `start` and `run` commands to debug aarch64 binaries with
### Qemu user-space emulation on port 1234.
### --------------------------------------------------------------------

# Temporary Files Created in the current working directory
# .tmp.gdb.log - GDB command and target output
# .tmp.gdb.src - temporary file for sourcing dynamic GDB commands
# .tmp.gdb.isStart - run was called by the start command if file exists
# .tmp.gdb.args - space-separated list of start's arguments

# Helpful resources:
# https://gist.github.com/nojhan/c3bc28e2fa0608f21551
# https://stackoverflow.com/a/17960363
# https://stackoverflow.com/a/12452235
# https://stackoverflow.com/a/15032459
# https://sourceware.org/gdb/onlinedocs/gdb/Command-History.html
# https://stackoverflow.com/q/25195501

# Execute run if aarch64 otherwise continue with start
define hook-start
  get-aarch64-args
  if ($aarch64)
    shell touch .tmp.gdb.isStart
    run
  end
end

define get-aarch64-args
  # Enable Logging
  shell rm -f .tmp.gdb.*
  set logging file .tmp.gdb.log
  set logging overwrite on
  set logging redirect on
  set pagination off
  set logging on

  # Get the arguments and target architecture.
  show commands
  info target
  show args

  # Disable Logging
  set logging off
  set pagination on
  set logging redirect off
  set logging overwrite off

  # Set Architecture
  shell echo -n 'set $aarch64 = 0' > .tmp.gdb.src
  shell if [[ -n $(grep "file type elf64-.*aarch64." .tmp.gdb.log) ]]; \
    then echo 1 >> .tmp.gdb.src; fi
  source .tmp.gdb.src

  # Get Arguments from `show commands`
  shell grep -o "start .*" .tmp.gdb.log | tail -1 | cut -c 7- > \
    .tmp.gdb.args

  # Get Arguments from `show args` if no arguments passed to start
  shell if [[ -z $(cat .tmp.gdb.args) ]]; then grep -o "started is .*" \
    .tmp.gdb.log | cut -c 13- | rev | cut -c 3- | rev > .tmp.gdb.args; \
    fi

  # Cleanup
  shell rm -f .tmp.gdb.log .tmp.gdb.src
end

python
### --------------------------------------------------------------------
### start.py
### Author: William Ughetta
### Overrides GDB run command to enable seamless aarch64 debugging.
### --------------------------------------------------------------------

import os.path
import re
import subprocess

class RunCommand(gdb.Command):
    """
    Overloads the default GDB run command to enable cross-platform
    aarch64 debugging by leveraging the default GDB start command.
    If file `.tmp.gdb.isStart` exists, behaves like start instead of
    run and uses arguments from the generated file `.tmp.gdb.args`.
    """
    def __init__ (self):
        super(RunCommand, self).__init__("run", gdb.COMMAND_RUNNING,
            gdb.COMPLETE_NONE)

    def invoke (self, args, from_tty):
        infoTarget = gdb.execute("info target", from_tty, True)
        target = re.search(r"/.*', file type", infoTarget)
        if not target:
            print("No executable file specified.\n" +
                  "Use the \"file\" or \"exec-file\" command.\n")
            return
        target = target.group(0)[:-12]
        aarch64 = re.search(r"file type elf64-.*aarch64.", infoTarget)
        if (aarch64):
            ## AArch64 Run
            isStart = os.path.isfile(".tmp.gdb.isStart")
            try:
                gdb.execute("kill", from_tty, True)
            except:
                pass
            subprocess.call("kill -9 $(ps -u | grep -m 1 " +
                "'qemu-aarch64 -g 1234' | " +
                "awk '{print $2}') 2>/dev/null", shell=True)
            gdb.execute("file " + target, from_tty, True)
            if isStart:
                with open(".tmp.gdb.args") as f:
                    args = f.read()[:-1]  # strip ending newline
                subprocess.call("rm -f " + ".tmp.gdb.args", shell=True)
            elif (not args):
                args = gdb.execute("show args", from_tty, True)[68:-3]
            gdb.execute("set args " + args, from_tty, True)
            print("Starting Qemu on Port 1234: " + target + " " + args)
            subprocess.call("qemu-aarch64 -g 1234 " + target + " " +
                args + " &>/dev/stdout </dev/stdin &", shell=True)
            gdb.execute("target remote :1234", from_tty, True)
            if isStart:
                gdb.execute("tbreak main", from_tty, True)
                subprocess.call("rm -f " + ".tmp.gdb.isStart",
                    shell=True)
            gdb.execute("continue", from_tty, True)
            if isStart:
                raise gdb.GdbError("\n") # Silences another message
        else:
            ## x86-64 Run
            gdb.execute("start " + args, from_tty)
            gdb.execute("continue", from_tty, True)

RunCommand()

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

Temporary breakpoint 1, main () at hello.s:6
6       stp x29, x30, [sp, #-16]!


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
(gdb)
```

Mix of two `start`'s and on `run` command on aarch64:

```
(gdb) start
Starting Qemu on Port 1234: /home/vagrant/hello/a.out
0x00000000004003f0 in _start ()

Temporary breakpoint 2, main () at hello.s:6
6       stp x29, x30, [sp, #-16]!


(gdb) n
8       adr x0, cMes
(gdb)
9       bl  printf
(gdb)
hello, world
11      mov w0, #0
(gdb) start

QEMU: Terminated via GDBstub
Starting Qemu on Port 1234: /home/vagrant/hello/a.out
0x00000000004003f0 in _start ()

Temporary breakpoint 3, main () at hello.s:6
6       stp x29, x30, [sp, #-16]!


(gdb) run

QEMU: Terminated via GDBstub
Starting Qemu on Port 1234: /home/vagrant/hello/a.out
0x00000000004003f0 in _start ()
hello, world
[Inferior 1 (Remote target) exited normally]
(gdb)
```

Again, note that aarch64 and x86-64 binaries cannot be debugged in
series without first quitting and re-starting GDB. An example of the
error is below:

```
(gdb) file hello
warning: Selected architecture i386:x86-64 is not compatible with \
reported target architecture aarch64
Architecture of file not recognized.
(gdb) start
Temporary breakpoint 4 at 0x400580: file hello.s, line 6.
Starting program: /home/vagrant/workspace/hello
Warning:
Cannot insert breakpoint 4.
Cannot access memory at address 0x555555954580

(gdb)
```
