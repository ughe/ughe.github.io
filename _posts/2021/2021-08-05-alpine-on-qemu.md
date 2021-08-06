---
title: "Alpine Linux on Qemu"
---

This post demonstrates how to setup a fresh installation of Alpine Linux on a virtual machine on macOS using [Qemu](https://www.qemu.org/download/). Copy-and-pastable commands are used as much as possible to avoid GUI setup.

## Codesign Qemu

In order to run Qemu with Apple's [hypervisor][0] framework on macOS, Qemu must be signed. In this post, we will use `qemu-system-x86_64`. On an M1 mac, `qemu-system-aarch64` should be used.

Create an `app.entitlements` file with the following contents:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.hypervisor</key>
	<true/>
</dict>
</plist>
```

Then sign Qemu using the `app.entitlements` as follows:

```bash
codesign -s - --entitlements app.entitlements --force `which qemu-system-x86_64`
```

For more resources on this topic, see [[1]] and [[2]].

## Download Alpine

```
ARCH="x86_64"
VER="3.14"
URL="https://dl-cdn.alpinelinux.org/alpine/v${VER}/releases/${ARCH}/alpine-virt-${VER}.0-${ARCH}.iso"
ISO=`basename $URL`

if [ ! -f $ISO ]; then
    curl -O $URL
    curl -O ${URL}.sha512
    SHA512=`cat *sha512 | awk '{print $1}'`
    SCHECK=`openssl dgst -sha512 alpine*.iso | awk '{print $2}'`
    if [ "${SHA512}" != "${SCHECK}" ]; then echo "[FATAL] Invalid hash: ${SCHECK}" >&2 && rm -f ${ISO}*; fi
fi
```

## Install Alpine

```bash
NAME=alpine
N_HD_GB=64
N_RAM_GB=4
N_CPU=2
qemu-img create -f vmdk "${NAME}".vmdk ${N_HD_GB}G
qemu-system-x86_64 -accel hvf -cpu max,enforce -m ${N_RAM_GB}G -smp $N_CPU -hda $NAME.vmdk -cdrom $NAME*.iso -nographic
```

Wait for the `localhost login:` prompt. Log in with `root`. Then paste in:

```bash
setup-keymap us us
setup-hostname "desktop-`hexdump -n4 -e'"%x"' /dev/urandom`"
setup-interfaces -a
rc-service networking start
rc-update add networking boot

setup-timezone -z America/New_York
setup-sshd -c none

echo -e 'https://alpine.global.ssl.fastly.net/alpine/v3.14/main\nhttps://alpine.global.ssl.fastly.net/alpine/v3.14/community\n' > /etc/apk/repositories

setup-ntp -c chrony

apk add adwaita-icon-theme chrony clang elogind emacs firefox g++ git htop ip6tables iptables lightdm-gtk-greeter make polkit-elogind setxkbmap sudo tmux vim xdg-utils xfce4 xfce4-terminal xorg-server

setup-xorg-base
X -configure
mv xorg.conf.new /etc/X11/xorg.conf
sed -i 's/#Option     "SWcursor/Option      SWcursor/' /etc/X11/xorg.conf
rc-update add dbus

iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
ip6tables -P FORWARD DROP
ip6tables -P INPUT DROP
ip6tables -A INPUT -m state --state ESTABLISHED -j ACCEPT
iptables -L
ip6tables -L
rc-update add iptables
rc-update add ip6tables
/etc/init.d/iptables save
/etc/init.d/ip6tables save

rc-update add lightdm

yes | setup-disk -m sys /dev/sda

reboot
```

After reboot, wait for the `localhost login:` prompt. Log in with `root`. Then paste in:

```boot
update-extlinux
sed -i 's/TIMEOUT 30/TIMEOUT 1/' /boot/extlinux.conf

sed -i 's/\/root:\/bin\/ash/\/root:\/sbin\/nologin/' /etc/passwd
echo "root:`tr -dc A-Za-z0-9 </dev/urandom | head -c 32`" | chpasswd
passwd -l root

echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
addgroup -g 1000 user
adduser -u 1000 -G user user
```

Next, enter a password twice for the new `user`.

And finally, type `adduser user wheel` and `poweroff`. The `root` user is now disabled.

## Launch Alpine GUI

```bash
qemu-system-x86_64 -accel hvf -cpu max,enforce -m 4G -smp 2 -hda ./alpine.vmdk
```

Note, we have replaced `N_RAM_GB` with `4G`; `N_CPU` with `2`; and `NAME` with `./alpine` above. Log in with the `user`'s password. Change the display resolution (Applications > Settings > Display).

## Troubleshooting

### mmu_gva_to_gpa

If Qemu is started with `-cpu host`, then an error of this form might occur eventually:

```
vmx_write_mem: mmu_gva_to_gpa ffff8a8d3fb19000 failed
```

Anecdotally, changing `-cpu host` to `-cpu max,enforce` works. See [[3]] for alternative suggestions, which are to specify the correct physical CPU or to use `-cpu qemu64`.

### VirtualBox

If Qemu fails, then try [VirtualBox](https://www.virtualbox.org).

Here are the equivalent commands:

```
NAME=alpine
N_HD_GB=64
N_RAM_GB=4
N_CPU=2
vboxmanage createvm --name "${NAME}" --ostype Linux_64 --register
vboxmanage createmedium disk --size $(( $N_HD_GB * 1024 )) --format VMDK --filename "${NAME}".vmdk
vboxmanage storagectl "${NAME}" --name SATA --add sata --bootable on
vboxmanage storageattach "${NAME}" --storagectl SATA --port 0 --device 0 --type hdd --medium "${NAME}".vmdk
vboxmanage storagectl "${NAME}" --name IDE --add ide
vboxmanage storageattach "${NAME}" --storagectl IDE --port 0 --device 0 --type dvddrive --medium "${NAME}"*.iso
vboxmanage modifyvm "${NAME}" --cpus $N_CPU --memory $(( $N_RAM_GB * 1024 )) --vram 64 --accelerate3d on --graphicscontroller vmsvga
vboxmanage modifyvm "${NAME}" --boot1 disk --boot2 dvd --boot3 none --boot4 none
vboxmanage modifyvm "${NAME}" --uart1 0x3F8 4 --uartmode1 server /tmp/tty0
vboxmanage startvm "${NAME}" --type headless
nc -U /tmp/tty0
```

Now that VirtualBox is started, follow along the same initialization commands [as described above](#install-alpine). Note: after rebooting, hit enter before typing in the `root` username, since control characters do not appear to be handled [[4]].

After copy and pasting all those commands, remove the installation disk and start in graphical mode:

```
vboxmanage storageattach "${NAME}" --storagectl IDE --port 0 --device 0 --type dvddrive --medium none
vboxmanage startvm "${NAME}"
```

After logging in as `user`, change the display resolution if needed (Applications > Settings > Display).

#### Miscellaneous VirtualBox Commands

To remove the headless serial connection:

```
vboxmanage modifyvm "${NAME}" --uart1 off
```

To turn off the virtual machine:

```
vboxmanage controlvm "${NAME}" poweroff soft
```

To delete the virtual machine:

```
vboxmanage list vms
vboxmanage unregistervm --delete "${NAME}"
```

## Coda

In this post, we aimed to run Alpine Linux on macOS using Qemu, with minimal user setup. We also showed how to use VirtualBox instead. If a VM is setup with VirtualBox, it can also be run with Qemu if the `*.vmdk` file is specified. For example, either command works `vboxmanage startvm alpine` or `qemu-system-x86_64 -accel hvf -cpu max,enforce -m 4G -smp 2 -hda ./alpine.vmdk`.

[0]: https://developer.apple.com/documentation/hypervisor
[1]: https://stackoverflow.com/a/64993771
[2]: https://www.reddit.com/r/VFIO/comments/kdhgni/qemu_hvf_support_for_mac_os_x_bug_sur_hv_error
[3]: https://stackoverflow.com/a/63746318
[4]: https://bluesock.org/~willg/dev/ansi.html
[5]: https://docs.oracle.com/en/virtualization/virtualbox/6.0/admin/vrde.html
