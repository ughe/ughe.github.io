---
layout: post
title: "Using Qemu within GDB"
categories: [gdb, qemu, arm64]
---

GDB has excellent support for native debugging as well as remote,
server-based debugging. To start a program natively, `start` and `run`
are useful commands. To debug remotely, GDB can be attached to a PID
or connected to a server. Qemu provides a GDB debug interface, which
has a lot of documentation online. The difficulty with this experience
is that it is more cumbersome to debug a remote server configuration,
such as with Qemu, than it is to debug a native program. This can be
fixed with a GDB command that allows a Qemu emulation to be run as if
it is a native program, which means abstracting the GDB server details
from the user.

To integrate Qemu into GDB, it is possible to create a command, let's
call it `qemu`, that will start running a binary in GDB using Qemu
user-space emulation. In this post, `qemu-aarch64` is used for arm64
emulation, although it could be a different architecture.

# Define the `qemu` command in GDB:

This command takes one argument only, which is the cross-compiled
binary to run.

Create a `~/.gdbinit` file with the following contents (or just type
this into GDB):

``` bash
define qemu
  if $argc != 1
      echo Usage: qemu a.out\n
  else
    shell kill -9 $(ps -u | grep -m 1 'qemu-aarch64 -g 1234' | awk '{print $2}') 2>/dev/null
    file $arg0
    shell qemu-aarch64 -g 1234 $arg0 &>/dev/stdout </dev/stdin &
    target remote :1234
    break main
    continue
  end
end
```

The `qemu` command is used inside of `gdb-multiarch`. First, it
attempts to kill the a process if it has `qemu-aarch64 -g 1234` in its
name, which is because there should only be one debug active at a time
or at least they must be using different port numbers. In this case,
1234 is the port number and only one debug is allowed at a time.

Next, the debug info is loaded with `file $arg0`. `arg0` is the first
argument given to `qemu`. For example, it could be `a.out`.

Then, GDB starts the remote Qemu user-space emulation with the
`shell qemu-aarch64 -g 1234 $arg0 &>/dev/stdout </dev/stdin &`
command. The `-g 1234` specifies the default port and the outputs are
redirected to standard out while the input is fed in stadard in. Also,
the process is run in the background so that GDB can continue. This is
the most important part of the command. It works using the GDB command
as well as inside of Emacs.  The standard input and output forwarding,
which is what makes it possible to do this concisely within GDB, does
not function only in the special case of using the non-Emacs GDB
command `layout src` or similar tui modes.

Finally, GDB is told to connect to Qemu with `target remote :1234`,
and it goes straight to `main`.

This approach to using Qemu within GDB is new with respect to the
dominant one, which is to just have two terminals and start Qemu using
`qemu-aarch64 -g 1234 a.out` on the first while opening GDB and using
`target remote :1234` on the second. While it can also be common to
run Qemu in the background, input and output is severily limited
without forwarding to standard in and out. This post aims to fix both
of these issues by creating a simple GDB command to facilitate arm64
cross-platform debugging on x86-64 machines.
