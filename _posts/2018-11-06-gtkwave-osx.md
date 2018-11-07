---
layout: post
title: "GTKWave on OSX"
categories: [gtkwave]
---

# [Motivation](#motivation)

While installing and running GTKWave is straightforward on Mac OSX, it
is slightly more difficult to get the command line tool running properly.

One conventional approach is to use `alias gtkwave = open -a gtkwave`;
however, this is lacking because it does not accept command line
arguments. Even using `--args` to pass arguments does not work. This
post demonstrates how to get it working using the
`/Applications/gtkwave.app/Contents/Resources/bin/gtkwave` executable.

# [Install](#install)

## [GTKWave](#gtkwave)

First, install GTKWave:

``` bash
brew tap homebrew/cask
brew cask install gtkwave
```

Although you can try just running the executable now, it will run into
an error if Perl's Switch module is not installed. This is done in the
next section.

## [Perl Switch](#perl-switch)

Using Perl's package manager, install Switch:

``` bash
cpan install Switch
perl -V:'installsitelib'
```

The last command prints out the location of where Switch is installed. If it is something like `/usr/local/Cellar/perl/...`, then Switch must be coppied to the correct location in `/Library/Perl/5.*/`:

``` bash
sudo cp /usr/local/Cellar/perl/5.*/lib/perl5/site_perl/5.*/Switch.pm /Library/Perl/5.*/
```

# [Run](#run)

Finally, the GTKWave command line tool can be run without any errors:

```
/Applications/gtkwave.app/Contents/Resources/bin/gtkwave
```

## [Add the command to ~/.bash_profile:](#add-the-command-to-bash_profile)

Now this can be added to the `~/.bash_profile` with:
``` bash
alias gktwave = /Applications/gtkwave.app/Contents/Resources/bin/gtkwave
```
or with:
``` bash
export PATH= /Applications/gtkwave.app/Contents/Resources/bin/:$PATH
```

# [Helpful References](#helpful-resources)
1. [A hacking attempt](https://superuser.com/q/1351190)
2. [A conventional approach for reference only](http://web02.gonzaga.edu/faculty/talarico/CP230/labs/LabT0/IverilogMac.pdf)
3. [The Manual](http://gtkwave.sourceforge.net/gtkwave.pdf#Apple-Macintosh-Operating-Systems)

From the manual (section: **Compiling and Installing GTKWave**):
> Note that if running GTKWave on the command line out of a precompiled bundle gtkwave.app, it is required that the Perl script gtkwave.app/Contents/Resources/bin/gtkwave is invoked to start the program.
