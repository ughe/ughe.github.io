---
title: "GTKWave Automation"
---

What if GTKWave could show all signals, zoom to fit, and save the graph
as a PDF every time it was openend? Using a TCL file, this is possible.

This post is a follow up to the last one, [GTKWave on OSX]({{ site.baseurl }}{% post_url 2018-11-06-gtkwave-osx %}), which covered installing the command line tool
on OSX. The goal of this post is to show how to automate opening GTKWave
files using TCL and a Makefile.

# gtkwave.tcl

The TCL file accomplishes three things: adding all signals, zooming to
fit, and printing out the signals to a PDF. There is a lot of documentation
available inside the manual for using GTKWave's functions. Also, the
final PDF printing can be disabled if it is cumbersome. The following
script will be invoked every time we start GTKWave from a Makefile:

``` tcl
### --------------------------------------------------------------------
### gtkwave.tcl
### Author: William Ughetta
### --------------------------------------------------------------------

# Resources:
# Manual: http://gtkwave.sourceforge.net/gtkwave.pdf#Appendix-E-Tcl-Command-Syntax
# Also see the GTKWave source code file: examples/des.tcl

# Add all signals
set nfacs [ gtkwave::getNumFacs ]
set all_facs [list]
for {set i 0} {$i < $nfacs } {incr i} {
    set facname [ gtkwave::getFacName $i ]
    lappend all_facs "$facname"
}
set num_added [ gtkwave::addSignalsFromList $all_facs ]
puts "num signals added: $num_added"

# zoom full
gtkwave::/Time/Zoom/Zoom_Full

# Print
set dumpname [ gtkwave::getDumpFileName ]
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Minimal $dumpname.pdf
```

# Makefile

The following Makefile is geared toward [ELE 206](https://registrar.princeton.edu/course-offerings/course_details.xml?courseid=002463&term=1192)
lab projects. Setting `TARGET` to the name of the pair of `.v` and
`.t.v` files

``` Makefile
### --------------------------------------------------------------------
### Makefile
### Author: William Ughetta
### --------------------------------------------------------------------

# Change This TARGET name:
TARGET = VerilogFile
TEST = $(TARGET)Test

GFLAGS = -S gtkwave.tcl
GTKWAVE_OSX = /Applications/gtkwave.app/Contents/Resources/bin/gtkwave

all: clean
	iverilog -g2005 -Wall -Wno-timescale -o $(TEST) $(TARGET).t.v
	vvp $(TEST)
	gtkwave $(GFLAGS) *.vcd 2>/dev/null || $(GTKWAVE_OSX) $(GFLAGS) *.vcd 2>/dev/null
clean:
	rm -f *.vcd
	rm -f *Test *test
zip:
	zip -r $$(basename $$(pwd)).zip *.v
```
