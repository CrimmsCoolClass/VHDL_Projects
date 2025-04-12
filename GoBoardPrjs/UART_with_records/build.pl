#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;

my $tb_top = "";

GetOptions(
    "top|t=s" => \$tb_top,
) or die "Error in commandline argument\n";

if (!$tb_top){
    die "Error: Need top VHDL entity.\n";
}

system ("ghdl -i --std=08 *.vhd");
system ("ghdl -i --std=08 --work=UART \$HOME/Documents/Code/VHDL/libraries/alex_custom/UART/*.vhd ");
system ("ghdl -m --std=08 top");

system("yosys -m ghdl -p \"ghdl --std=08 top; synth_ice40 -json design.json\"");
system("nextpnr-ice40 --hx1k --freq 25 --pcf ../GBC.pcf --json design.json --package vq100 --asc bitstream.txt");
system("icepack bitstream.txt bitstream.bin");
unlink("design.json",  "bitstream.txt");
print "Use \"iceprog bitstream.bin\" to program FPGA\n";

