---
layout: post
title: "Using Qemu within GDB Part 6"
categories: [gdb, qemu, arm64]
---

This post is the final in an unexpectedly long series (Parts
[1]({{ site.baseurl }}{% post_url 2018-08-14-qemu-gdb-integration %})
[2]({{ site.baseurl }}{% post_url 2018-08-20-qemu-gdb-integration-part-2 %})
[3]({{ site.baseurl }}{% post_url 2018-08-23-qemu-gdb-integration-part-3 %})
[4]({{ site.baseurl }}{% post_url 2018-08-24-qemu-gdb-integration-part-4 %})
[5]({{ site.baseurl }}{% post_url 2018-08-25-qemu-gdb-integration-part-5 %}))
in making Qemu work within GDB for seamless cross-debugging.

Debugging GDB native binaries is simple and quick. The goal of these
posts has been to make debugging arm64 binaries on GDB just as easy.
This is accomplished by having `gdb-multiarch` spin up Qemu automatically
to perform user-space emulation for binaries cross-compiled with the
`-static` flag. This allows the user to avoid having to type a series
of commands, including `target remote :1234`.

Qemu within GDB works with just one `~/.gdbinit` configuration file by
overloading the `start` and `run` commands to actually call Qemu on
the binary if the target is `aarch64`. Note that `x86-64` native
binaries still work unchanged.

# [Version 6](#version-6)

The following 6th version fixes a regression that worked in the first
attempt of Part 2, which was IO redirection (i.e. `scanf` and `printf`).
It also makes the printing slightly neater and more identical to `x86-64`.

See [the patch below]({{ site.baseurl }}{% post_url 2018-08-27-qemu-gdb-integration-part-6 %}#patch-from-version-5) for the diffed changes.

``` python
### --------------------------------------------------------------------
### .gdbinit
### Author: William Ughetta
### Overloads `start` and `run` commands to debug aarch64 binaries with
### Qemu user-space emulation on port 1234.
### --------------------------------------------------------------------

define hook-start
  set-aarch64
  if ($aarch64)
    qemu
  end
end

document hook-start
Binds the qemu command to the start command for aarch64 binaries.
end

define hook-run
  set-aarch64
  if ($aarch64)
    set $isRun = 1
    qemu
  end
end

document hook-run
Binds the qemu command to the run command for aarch64 binaries.
end

define set-aarch64
  python
if ("aarch64" in gdb.execute("info target", False, True)):
    gdb.execute("set $aarch64 = 1", False, True)
else:
    gdb.execute("set $aarch64 = 0", False, True)
  end
end

document set-aarch64
Sets convenience variable $aarch64 if the target architecture is
aarch64.
end

python
import re

class QemuCommand(gdb.Command):
    """The qemu command starts the current target using Qemu on port
1234."""
    def __init__ (self):
        super(QemuCommand, self).__init__("qemu", gdb.COMMAND_RUNNING,
            gdb.COMPLETE_FILENAME)

    def invoke (self, args, from_tty):
        ## Get target
        it = gdb.execute("info target", False, True)
        target = re.search(r"/.*', file type", it)
        if target:
            target = target.group(0)[:-12]
            gdb.execute("set $target = \"" + target + "\"", True)
        else:
            raise gdb.GdbError("No symbol table loaded.  " +
                  "Use the \"file\" command.")

        ## Check target architecture
        if (not re.search(r"file type elf64-.*aarch64.", it)):
            raise gdb.GdbError("Target binary file must be aarch64.")

        ## Check GDB Mode
        if ("aarch64" not in
            gdb.execute("show architecture", from_tty, True)):
            raise gdb.GdbError("Please restart GDB with an aarch64 " +
                "binary. Multiple architectures cannot \nbe debugged " +
                "in the same session.")

        ## Kill existing processes
        try:
            gdb.execute("kill", False, True)
        except:
            pass
        gdb.execute("shell kill -9 $(ps -u | grep -m 1 'qemu-aarch64 " +
            "-g 1234' | awk '{print $2}') 2>/dev/null", from_tty, True)

        ## Reselect file
        gdb.execute("file " + target, from_tty, True)
        gdb.execute("set remote exec-file " + target, from_tty, True)

        ## Get Args
        if (not args):
            c = gdb.execute("show commands", False, True)
            args = re.findall(r"((\n|^) *\d+  (start |run |r ).*)", c)
            if (len(args)):
                args = args[-1][0].strip("\n");
                if (args[7:10] == "run"):
                    args = args[11:]
                elif (args[7] == "r"):
                    args = args[9:]
                else: # == "start"
                    args = args[13:]
            if (not args or args == ""):
                args = gdb.execute("show args", False, True)[68:-3]
        gdb.execute("set args " + args, False, True)

        ## Start
        print("Starting Qemu on Port 1234: " + target + " " + args)
        gdb.execute("shell qemu-aarch64 -g 1234 " + target + " " +
            args + " &>/dev/stdout </dev/stdin &", from_tty, True)
        gdb.execute("target remote :1234", from_tty, True)
        isRun = gdb.execute("output $isRun", from_tty, True)
        if ("1" in isRun):
            gdb.execute("set $isRun = 0", from_tty, True)
        else:
            gdb.execute("tbreak main", from_tty, True)
        gdb.execute("continue", from_tty)
        raise gdb.GdbError("\033[F")

QemuCommand()

end

```

# [Patch From Version 5](#patch-from-version-5)

The following patch shows the differences between this post and the
last, [Version 5]({{ site.baseurl }}{% post_url 2018-08-25-qemu-gdb-integration-part-5 %}):

The changes are subtle but make a big difference:

1) Fixed IO redirection. This was originally working in
[Part 2]({{ site.baseurl }}{% post_url 2018-08-20-qemu-gdb-integration-part-2 %}#first-attempt).
By redirecting using the GDB command `shell` instead of `subprocess.call`,
the input/output pipes are setup correctly.

2) Cleaned up the `qemu` GDB prompt by deleting the empty line with the
opposite of the newline character `\n`, which is the [ansi escape code](https://stackoverflow.com/a/11474509)
`\033[F`.

``` diff
 python
-import os.path
 import re
-import subprocess

 class QemuCommand(gdb.Command):
     """The qemu command starts the current target using Qemu on port
@@ -81,8 +79,8 @@ class QemuCommand(gdb.Command):
             gdb.execute("kill", False, True)
         except:
             pass
-        subprocess.call("kill -9 $(ps -u | grep -m 1 'qemu-aarch64 -g" +
-            " 1234' | awk '{print $2}') 2>/dev/null", shell=True)
+        gdb.execute("shell kill -9 $(ps -u | grep -m 1 'qemu-aarch64 " +
+            "-g 1234' | awk '{print $2}') 2>/dev/null", from_tty, True)

         ## Reselect file
         gdb.execute("file " + target, from_tty, True)
@@ -106,8 +104,8 @@ class QemuCommand(gdb.Command):

         ## Start
         print("Starting Qemu on Port 1234: " + target + " " + args)
-        subprocess.call("qemu-aarch64 -g 1234 " + target + " " + args +
-                        " &>/dev/stdout </dev/stdin &", shell=True)
+        gdb.execute("shell qemu-aarch64 -g 1234 " + target + " " +
+            args + " &>/dev/stdout </dev/stdin &", from_tty, True)
         gdb.execute("target remote :1234", from_tty, True)
         isRun = gdb.execute("output $isRun", from_tty, True)
         if ("1" in isRun):
@@ -115,7 +113,7 @@ class QemuCommand(gdb.Command):
         else:
             gdb.execute("tbreak main", from_tty, True)
         gdb.execute("continue", from_tty)
-        raise gdb.GdbError("(gdb)")
+        raise gdb.GdbError("\033[F")

 QemuCommand()
```

# [References](#references)

This is the full list of helpful references that contributed to the
various iterations from parts 1-6. It turned out GDB's documentation
answered most of these questions, although it can be hard to find at
first:

Some of the most helpful parts of GDB's documentation were:

- [22.3 Command History](https://sourceware.org/gdb/onlinedocs/gdb/Command-History.html)
- [23.1.1 User-defined Commands](https://sourceware.org/gdb/current/onlinedocs/gdb/Define.html#Define)
- [23.2.2 Python API](https://sourceware.org/gdb/current/onlinedocs/gdb/Python-API.html#Python-API)

and Online Threads:

- Most important one: [https://stackoverflow.com/q/25195501](https://stackoverflow.com/q/25195501)
showed `set history filename`, which led to [documentation](https://sourceware.org/gdb/onlinedocs/gdb/Command-History.html).
- \033[F escape code: [https://stackoverflow.com/a/11474509](https://stackoverflow.com/a/11474509)
- Ignore GDB command: [https://stackoverflow.com/a/17960363](https://stackoverflow.com/a/17960363),
which points to Tom Tromey's comment here: [http://sourceware.org/ml/gdb/2010-06/msg00100.html](http://sourceware.org/ml/gdb/2010-06/msg00100.html).
- The original logging solution in Parts 1-4: [https://stackoverflow.com/a/12452235](https://stackoverflow.com/a/12452235)
- Putting Python in `~/.gdbinit`, of course: [https://stackoverflow.com/a/15032459](https://stackoverflow.com/a/15032459)
- The arguments problem, articulated: [https://gist.github.com/nojhan/c3bc28e2fa0608f21551](https://gist.github.com/nojhan/c3bc28e2fa0608f21551)
