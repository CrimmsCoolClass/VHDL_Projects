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
system ("ghdl -m --std=08 top_tb");
system ("ghdl -r --std=08 top_tb --wave=waveform.ghw");
