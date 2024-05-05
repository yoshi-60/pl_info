#!/usr/bin/perl -w

use strict;
use warnings;
use Verilog::Netlist;

if (@ARGV<3) {
    die qq/module_name file_list outfile required !/;
}
my $moduleN = $ARGV[0];
my $fileIn  = $ARGV[1];
my $fileOut = $ARGV[2];

open my $fhIn, '<', $fileIn
  or die qq/Can't open file "$fileIn" : $!/;
open my $fhOut,'>', $fileOut
  or die qq/Can't open file "$fileOut" : $!/;

my @FileList = ();
while (my $lineIn = <$fhIn>) {
  chomp $lineIn;
  push(@FileList, $lineIn);
}
close $fhIn;

print "  Search module: ", $moduleN, "\n";

my $NetList = new Verilog::Netlist(link_read_nonfatal=> 1,);
ReadVerilogFiles($NetList, \@FileList);
PrintInstance($NetList);

sub ReadVerilogFiles {
  my ($netlist, $r_filelist) = @_;

  foreach my $file (@{$r_filelist}) {
    $netlist->read_file(filename=>$file);
  }

  $netlist->link(); # connection resolve
}

sub PrintInstance {
  my ($netlist) = @_;

  my $inst_num = 0;
  foreach my $module ($netlist->modules_sorted) {
    foreach my $cell ($module->cells_sorted) {
      if ($cell->submodname =~ $moduleN ){
        my $moduleI = $netlist->find_module($cell->submodname);
        print '  ', $module->name,'  ',$cell->submodname, '  ', $cell->name;
        if ($netlist->find_module($cell->submodname)) {
          my @ports = $moduleI->ports_ordered;
          if ($#ports == -1) { next; }
          $inst_num++;
        }
        else {
          print " -- module net not found.";
          next;
        }
        print "\n";
        print $fhOut "// module: ", $module->name,"  cell: ",$cell->submodname,"  instance: ",$cell->name, "\n";
        print $fhOut ' 'x4, $cell->submodname, ' ', $cell->name, " (\n";
        my @cell_pins = $cell->pins_sorted;
        for (my $index=0; $index <= $#cell_pins; $index++) {
          my $pin_name = $cell_pins[$index]->name;
          my $portI    = $moduleI->find_port($pin_name);
          printf $fhOut "        %-32s %-32s",".".$pin_name, "(".$cell_pins [$index]->netname.")";
          if ($index != $#cell_pins) {
            print $fhOut ",";
          } else {
            print $fhOut " ";
          }
          print $fhOut " // ";
          if(defined($portI)) {
            print $fhOut $portI->direction;
            if(defined($portI->net->width) && $portI->net->width != 1) {
              print $fhOut '[', $portI->net->msb, ':', $portI->net->lsb, ']';
            }
          }
          print $fhOut "\n";
        }
        print $fhOut ' 'x4, ");\n";
      }
    }
  }
  print "  Total: ",$inst_num," instance found.\n";
}
close $fhOut;
