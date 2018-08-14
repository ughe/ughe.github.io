---
layout: post
title: "Using Qemu within GDB"
categories: [gdb, qemu, arm64]
---

Debugging arm64 programs is slightly easier natively on an [arm64
server](https://www.scaleway.com/) or a Raspberry Pi with a 64-bit
operating system. However, it is often more convenient to write arm64
code using existing x86-64 machines. This post aims to make debugging
arm64 code with GDB on x86-64 machines just as efficient as natively.

Qemu is a tool that is able to provide user-space emulation for arm64
(called "aarch64") and many other architectures. Qemu is able to
connect to GDB through its remote server interface. This can be much
clunkier than GDB's native `start` command because either two
terminals are needed or Qemu needs to be run in the background, which
can make input and output more difficult.

To integrate Qemu into GDB, a command can be created to make running
a remote server just as easy as the native `start` command. Let's call
it `qemu` (it will be invoked inside of GDB).

# Define the `qemu` command in GDB:

Create a `~/.gdbinit` file with the following contents (or just type
this into GDB):

``` bash
define qemu
  if $argc != 1
      echo Usage: qemu a.out\n
  else
    file $arg0
    shell qemu-aarch64 -g 1234 $arg0 &>/dev/stdout </dev/stdin &
    target remote :1234
    break main
    continue
  end
end
```

The `qemu` command takes one argument only, which is the arm64 binary
that it will run.

First, the debug info is loaded with `file $arg0`. `arg0` is the first
argument given to `qemu`. For example, it could be `a.out`. Next, GDB
starts the remote Qemu user-space emulation with the
`shell qemu-aarch64 -g 1234 $arg0 &>/dev/stdout </dev/stdin &`
command. The `-g 1234` specifies the default port 1234. This means
that there can only be one debug at a time because it only attempts to
use one port. The redirects allow Qemu to write to standard output and
read from standard input even while it is in the background. The only
restriction is this does not work with the GDB tui (i.e.
`layout src`). It does work with Emacs and GDB in its normal mode.
Finally, GDB is told to connect to Qemu with `target remote :1234`,
and it goes straight to `main`.
