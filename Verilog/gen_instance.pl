#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Std;
use Verilog::Netlist;

my %opt = ();
getopts("hi", \%opt);
if ($opt{h}) { &help(); }
if ($opt{i}) { &MkInst(); }

sub help()
{
    print << "ENDLINE";
Usage: ${0} [Optin]
Option:
    -h        :help
    -i fliset :specify each rtl to make instances
ENDLINE
}

sub MkInst {
    my $fileIn = $ARGV[0]
    open my $fhIn ,'<', $fileIn
      or die qq/Can't open file "$fileIn" : $i/;

    my @FileList = ();
    while (my $lineIn = <$fhIn>) {
      chomp $lineIn;
      push( `FileList, $lineIn);
    }
    close $fhIn;

    my $NetList = new Verilog::Netlist(link_read_nonfatal=> 1,);
    &ReadVerilogFiles($NetList, \@FileList);

    &PrintWire($NetList);
    &PrintInstance($NetList);
}

sub ReadVerilogFiles {
    my ($netlist, $r_filelist) = @_;

    foreach my $file (@{$r_filelist}) {
        $netlist->read_file(filename=>$file);
    }

    $netlist->link(); # connection resolve
}

sub PrintWire {
    my ($netlist) = @_;

    foreach my $module ($netlist->modules_sorted) {
        my @ports = $module->ports_ordered;
        if ($#ports == -1) { next; }

        my @width;
        my $max2 = 0;
        my $max3 = 0;
        for (my $index=0; $index <= $#ports; $index++) {
            my $size = 0;

            if (defined($ports[$index]->net->width) && $ports[$index]->net->width != 1) {
                push(@width, sprintf("[%s:%s] ", $ports[$index]->net->msb, $ports[$index]->net->lsb));
            }
            else {
                push(@width, "");
            }
            $size = length($width[$index]);
            if ($max2 < $size) { $max2 = $size; }

            $size = length($ports[$index]->name);
            if ($max3 < $size) { $max3 = $size; }
        }

        for (my $index=0; $index <= $#ports; $index++) {
            print ' 'x4, "wire ", $width[$index], ' 'x($max2-length($width[$index]));
            print "w_",  $ports[$index]->name,    ' 'x($max3-length($ports[$index]->name)), ';';
            print "\n";
        }

        print "\n";
    }
}

sub PrintInstance {
    my ($netlist) = @_;

    foreach my $module ($netlist->modules_sorted) {
        #my @ports = $module->ports_ordered;
        my @ports = $module->ports_sorted;
        if ($#ports == -1) { next; }

        print ' 'x4, $module->name, ' ', $module->name, "_0 (\n";

        my $max3 = 0;
        for (my $index=0; $index <= $#ports; $index++) {
            my $size = length($ports[$index]->name);
            if ($max3 < $size) { $max3 = $size; }
        }

        for (my $index=0; $index <= $#ports; $index++) {
            print ' 'x8, '.', $ports[$index]->name, ' 'x($max3-length($ports[$index]->name));
            print '(', "w_",  $ports[$index]->name, ' 'x($max3-length($ports[$index]->name)), ')';
            if ($index != $#ports) { print ","  }
            else                   { print " "; }
            print " // ", $ports[$index]->direction;
            if (defined($ports[$index]->net->width) && $ports[$index]->net->width != 1) {
                print '[', $ports[$index]->net->msb, ':', $ports[$index]->net->lsb, ']';
            }
            print "\n";
        }

        print ' 'x4,");\n";
        print "\n";
    }
}
