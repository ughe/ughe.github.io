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
import subprocess

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

        ## Check it is a static binary
        dl = subprocess.check_output("readelf -d " + target, shell=True)
        if (b"There is no dynamic section in this file." not in dl):
            raise gdb.GdbError("Error: aarch64 binary must be compiled" +
                " with the -static flag.")

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
