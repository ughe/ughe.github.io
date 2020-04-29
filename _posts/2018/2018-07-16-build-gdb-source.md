---
title: "Building GDB from Source"
---

This post covers compiling the GDB source code on an x86 or amd64
machine, in order to set up a local development environment. Note that
it may take over an hour.

# Download Linux Hypervisor

* Install [virtualbox](https://www.virtualbox.org/wiki/Downloads) and
[vagrant](https://www.vagrantup.com/downloads.html).

* Install a [debian box](https://app.vagrantup.com/debian) by running:

``` bash
vagrant init debian/stretch64
vagrant up
```

# Install Dependencies

``` bash
vagrant ssh
sudo apt-get build-dep gdb
sudo apt-get install -y texinfo flex bison dejagnu
sudo apt-get install -y emacs vim git automake
git clone git://sourceware.org/git/binutils-gdb.git gdb
```

[Dependencies Reference](https://sourceware.org/gdb/wiki/BuildBot#Debian-specific_instructions)

# Compile and Test

``` bash
cd gdb
./configure --enable-targets=all --with-expat
make
sudo make install
make check -j4 >& output.log
logout
vagrant halt
```

[Testing Reference](https://sourceware.org/gdb/wiki/TestingGDB)

For a more comprehensive guide, "[Working on GDB](https://gbenson.net/?p=292)"
from gbenson.net is an excellent resource.
