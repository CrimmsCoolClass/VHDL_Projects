#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my @supporting_files;
my $top_file = "";
my $top_entity;
GetOptions(
    "top|t=s"  => \$top_entity,
) or die "Error in command line arguments\n";

if (!$top_entity){
    die "Error: Need top VHDL file.\n";
}


print "Analyzing $top_entity ...\n";
system("ghdl -i --std=08 *.vhd");
system("ghdl -m --std=08 $top_entity");

print "Synthesizing with Yosys...\n";
system("yosys -m ghdl -p \"ghdl --std=08 $top_entity; synth_xilinx -abc9 -family xc7 -json design.json\"");

print "Running nextpnr...\n";
system("nextpnr-xilinx --chipdb ~/nextpnr-xilinx/xilinx/xc7a35t.bin --xdc ../../Basys-3-Master.xdc --json design.json --fasm design.fasm");

print "Converting frames...\n";
system("python3 ~/prjxray/utils/fasm2frames.py --db-root ~/prjxray/database/artix7 --part xc7a35tcpg236-1 design.fasm > design.frames");

print "Packing bitstream...\n";
system("~/prjxray/build/tools/xc7frames2bit -frm_file design.frames -output_file design.bit -part_name xc7a35tcpg236-1 -part_file ~/prjxray/database/artix7/xc7a35tcpg236-1/part.yaml");

print "Cleaning workspace...\n";
unlink("design.json", "design.fasm", "design.frames", "work-obj08.cf");

print "Ready to prog!\n";
