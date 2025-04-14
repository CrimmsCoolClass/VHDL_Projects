#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $tb_top = ""; #ENTITY NAME ONLY!

GetOptions(
  "top|t=s" => \$tb_top,
) or die "Error in commandline argument\n";

if (!$tb_top){
  die "Error: Need top VHDL entity.\n";
}

system("ghdl -i --std=08 *.vhd");
system("ghdl -m --std=08 $tb_top");
system("ghdl -r --std=08 $tb_top --wave=waveform.ghw");
print "Use GTKWave to view waveform.\n";
