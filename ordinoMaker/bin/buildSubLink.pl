#
# Name: buildSubLink.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use strict;
use warnings;

print "$0\n";

# Variable #
my $libDir = "../lib";
my (@files, @funcs);
my %Hfunctions;
my @filesBin = ("main.pl","launcher.pl");

open my $fh_vg, '>', "../tmp/buildSubLink.gv" or die $!;

##########################################
sub getSub {
	my $file = shift;
	
	open my $fh_file, '<', $file or die $!;
	
	my $filebase = (split(/\// , $file))[-1] ;
	push(@files, $filebase );
	
	while ( my $line = <$fh_file>) {
		if ( $line =~ m/^sub\s/ ) { 
			my $nameFunction = (split(/ / , $line))[1];
			push( @{$Hfunctions{$filebase}}, $nameFunction ) ;
		}
	}
	close $fh_file or die $! ;
}

sub getLink {
	my $file = shift;
	my $color = "black";
	my @colors = qw(black blue red2 green slateblue4 violetred4 chocolate4 darkorange goldenrod3 deeppink3 azure4);
	my $i = 0;
	open my $fh_file, '<', $file or die $!;
	
	$file = (split(/\//, $file))[-1];
		my $csub = $file ;
	
	while ( my $line = <$fh_file>) {
		next if ( $line =~ m/^#|^$|^\s#/ );
		if ( $line =~ m/^sub\s/ ) { $csub = (split(/ / , $line))[1] ; next};
		if ( $line =~ m/^\}$/ )  { $csub = $file ; }
		foreach ( @funcs ) {
			if ( $line =~ m/$_\(/ ) {
				print {$fh_vg} "\"$csub\" -> \"$_\" [color=\"$colors[$i]\"] \;\n" ;
				$i++;
				if ( ! $colors[$i] ) { $i = 0; }
			}
		}
	}
		
	close $fh_file or die $! ;		
}

##########################################
print "\n=> Get Sub\n";
# bin #
foreach ( @filesBin ) {	getSub($_) ;}
# lib #
opendir(DIR, $libDir) or die $!;
while ( readdir(DIR) ) {
	next if ($_ !~ m/^lib\_.+\.pl$/ );
	getSub("$libDir/$_");
}
closedir(DIR) or die $!;

##########################################
print "\n=> Files\n";
foreach ( @files ) { print "\t$_\n"}

print "\n=> Files / Fonctions\n";
for my $key ( sort keys %Hfunctions ) { 
	print "  $key\n"; 
	foreach ( @{$Hfunctions{$key}} ) {
		print "\t$_\n";
		push (@funcs, $_);
	}
}

##########################################
# Build vg file
print {$fh_vg} "digraph {
	graph [ fontsize=15 splines=false overlap=true shape=record  style=\"radial\" rankdir = \"LR\"];
	node [shape=record fontsize=10];
	ratio=\"auto\";\n\n" ;

for my $key ( sort keys %Hfunctions ) { 
	( my $keyNoDo = $key ) =~ s/\./_/g;
	print {$fh_vg} "subgraph cluster_$keyNoDo {\n";
	foreach ( @{$Hfunctions{$key}} ) { 	print {$fh_vg} "\"$_\"\;\n"; }
	print {$fh_vg} "\nlabel = \"$key\";\n}\n\n";
}

#########################################
print "\n=> Get Link\n";
# bin #
foreach ( @filesBin ) {	getLink($_); }
# lib #
opendir(DIR, $libDir) or die $!;
while ( readdir(DIR) ) {
	next if ($_ !~ m/^lib\_.+\.pl$/ );
	getLink("$libDir/$_");
}
closedir(DIR) or die $!;


print {$fh_vg} "}\n";
close $fh_vg or die $!;
