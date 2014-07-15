#
# Name: main_calMaker.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use strict;
use warnings;
use Date::Holidays::FR;
use Spreadsheet::WriteExcel;
require("./ordinoMaker/lib/lib_regexp.pl");
require("./ordinoMaker/lib/lib_utils.pl");

################################################################################
# variable
my $vpn;
my $fh_cal;
my $fh_Xref;
my $getEnvVPN		= 'ordinoMaker\bin\getEnvVPN.cmd';
my $getTwsCal		= 'ordinoMaker\bin\getTwsCal.cmd';
my $getTwsXref	= 'ordinoMaker\bin\getTwsXref.cmd';
my $i = 1;

my %Hcal;
my %Hcpu;
my %Hopt;

################################################################################
# Option ordinoMaker/etc/calMaker.conf
open my $fh_opt, '<', "ordinoMaker/etc/calMaker.conf" or die $!;
while ( my $line = <$fh_opt> ) {
	next if ( $line =~ /^\s*$|^#/  );
	chomp($line);
	
	my ($key,$value) = split("=",$line);
	$Hopt{$key} = $value;
}
close $fh_opt;

my @alloweduser = split(/\;/, $Hopt{'alloweduser'});
my $granted = 0;

foreach ( @alloweduser ) {
	if ( "$ENV{'USERNAME'}" eq "$_") { $granted = 1 };
}

if ( $granted == 0) {	die("\n ! $ENV{'USERNAME'} - Vous n etes pas autorise a utiliser calMaker !\n\n") }

################################################################################
# envVpn()
# Recupérer l'env VPN : Qualif / Prod / KO
# global var :
# return	(string)
sub envVpn {
	my $cr = "error";
	system($getEnvVPN);
	if ( $? == 0		) { $cr = "KO" }
	if ( $? == 256	) { $cr = "Prod" }
	if ( $? == 512	) { $cr = "Qualif" }
	return("$cr");
}

################################################################################
# VPN
print "-------------------\n";
print "Controle du VPN\n";
$vpn = envVpn();
# $vpn = "Prod";

if ( $vpn ne "Prod" && $vpn ne "Qualif" ) {
	die "Merci de connecter un VPN !\n";
} else {
	print "   Environnement : $vpn \n";
}

################################################################################
# Get files
print "-------------------\n";
print "Get tws calendrier\n";
system("$getTwsCal $vpn _calendrier\\$vpn");

print "-------------------\n";
print "Get tws xref \-when\n";
system("$getTwsXref $vpn _calendrier\\$vpn");

################################################################################
# calendar
print "-------------------\n";
print "Prise en compte du fichier calendrier\n";

open $fh_cal, '<:encoding(cp1252)', "_calendrier/$vpn/calendar_$vpn.txt" or die $!;
my $ccal;

while ( my $line = <$fh_cal> ) {
	chomp($line);
	next if ( $line =~ /^\$CALENDAR$/ || 	$line =~ /^\s*$/ );

	# get calendar name
	unless ( $line =~/^\s/ ) {
			trim(\$line);
			$ccal = $line;
			$Hcal{$line}{'num'} = $i;
			$i++;
			next;
	}

	# get definition
	if ( $line =~/^\s*\"/ ) {
		trim(\$line);
		$line =~ s/\"//g;
		$Hcal{$ccal}{'def'} = $line;
		next;
	}

	# get date populate
	trim(\$line);
	my @pop = split(/\ /, $line);
	push(@{$Hcal{$ccal}{'pop'}}, @pop);
}
close $fh_cal;



################################################################################
# Xref -when
print "-------------------\n";
print "Prise en compte du fichier Xref\n";

open $fh_Xref, '<:encoding(cp1252)', "_calendrier/$vpn/Xref_when_$vpn.txt" or die $!;
my $ccpu;
while ( my $line = <$fh_Xref> ) {
	chomp($line);
	next if ( $line =~ /^\s*$/ );
	next if ( $line =~ /^WHEN|^FREQ\=|^Report|Page|^\s|^[0-9][0-9]\// );

	# get CPU
	if ( $line =~ /^CPU:\ / ) {
		( $ccpu = $line ) =~ s/^CPU: //;
			trim(\$ccpu);
		 $i++;
		 next;
	}
	next if ( ! $ccpu );

	trim(\$line);
	my $cal = (split(/\s/, $line))[0];
	$cal =~ s/\*$|f$//;
	if ( ! $Hcal{$cal} ) { print " Warning $ccpu : $cal calendrier inexistant\n"; next; }
	$Hcpu{$ccpu}{$cal} = 1;
}
close $fh_Xref;


################################################################################
# check HOLIDAYS
print "-------------------\n";
print "Controle HOLIDAYS\n";

foreach ( @{$Hcal{'HOLIDAYS'}{'pop'}} ) {
	my ($month, $day, $year) = split(/\//, $_);
	print " Warning : $_\n" if ! is_fr_holiday($year, $month, $day);
}


################################################################################
# Create xls
print "-------------------\n";
print "Creation du fichier Excel\n";

my $file			= "_calendrier/$vpn/calendrier_$vpn.xls";
my $worksheet	= "calendrier";
my $workbook;

# Chk si creation fichier OK ?
open(STDERR,'>/dev/null') or die $! ;
eval {
	$workbook = Spreadsheet::WriteExcel->new($file) or die $!;
};
close(STDERR) or die $! ;
if ($@) {	die("Creation $file KO !\n\t$@"); }

my $worksheet1 = $workbook->add_worksheet($worksheet);

# Colonne de $worksheet1 => Jobstream Definition

# Definition des formats
my $format_tok = $workbook->add_format(	
	center_across =>	1,
	size					=>	8,
	border 				=>	1,
	color 				=>	'black',
	bg_color 			=>	'cyan',
	align 				=>	'vcenter');
	$format_tok->set_rotation(90);
my $format_tko = $workbook->add_format(	
	center_across =>	1,
	size					=>	8,
	border 				=>	1,
	color 				=>	'black',
	bg_color 			=>	'red',
	align 				=>	'vcenter');
	$format_tko->set_rotation(90);
my $format_key 	= $workbook->add_format(	
	border 				=>	1,
	bg_color 			=>	'yellow',
	align 				=>	'vcenter');
my $format_valueMain = $workbook->add_format(	
	size				 	=>	8,
	bg_color			=>	'green',
	border 				=>	1,
	align 				=>	'vcenter');



# x
$i = 1;
my $col;
foreach my $cpu ( sort keys %Hcpu ) {
	$worksheet1->write($i, 0, $cpu, $format_key);

	foreach my $cal ( keys %{$Hcpu{$cpu}} ) {
		my $col = $Hcal{$cal}{'num'};
		$worksheet1->write($i, $col, "x", $format_valueMain);
		push(@{$Hcal{$cal}{'usedby'}}, $cpu);
	}
	
	$i++;
}

# figer les volets
$worksheet1->freeze_panes(1, 1);
# Largeur colonne
my $count = keys %Hcal;
$worksheet1->set_column(0, 0, 10);
$worksheet1->set_column(1, $count, 2);
# Hauteur ligne 0
$worksheet1->set_row(0, 80);
# Fitre automatique
$worksheet1->autofilter(0, 0, $i, $count);


# Ecriture des titres de $worksheet1
# red si calendrier non utilise
# et commentaire
$worksheet1->write(0, 0, "CPU", $format_tok);

foreach my $cal ( sort keys %Hcal ) {
	my $col = $Hcal{$cal}{'num'};
	my $com = $Hcal{$cal}{'def'};
	
	$worksheet1->write_comment(0, $col, $com);
	
	if ( $Hcal{$cal} && ( ! $Hcal{$cal}{'usedby'} ) ) {
		$worksheet1->write(0, $col, $cal, $format_tko);
	} else {
		$worksheet1->write(0, $col, $cal, $format_tok);
	}
}

# __END__

################################################################################
# Dump hash
print "-------------------\n";
print "Creation des logs\n";
open my $fh_log_cal, '>:encoding(utf-8)', "_calendrier/$vpn/calendrier.log" or die $!;
open my $fh_log_Xref, '>:encoding(utf-8)', "_calendrier/$vpn/Xref_when.log" or die $!;

print "   calendrier.log\n";
my $dump_hash = dumperHash(%Hcal);
$dump_hash =~ s/\"\,\n\s*\"/\"\, \"/g;
$dump_hash =~ s/\[\n\s*/\[ /g;
$dump_hash =~ s/\n\s*\]/ \]/g;
print {$fh_log_cal} "\n$dump_hash\n";

print "   Xref_when.log\n";
$dump_hash = dumperHash(%Hcpu);
$dump_hash =~ s/\"\,\n\s*\"/\"\, \"/g;
$dump_hash =~ s/\[\n\s*/\[ /g;
$dump_hash =~ s/\n\s*\]/ \]/g;
print {$fh_log_Xref} "\n$dump_hash\n";

close $fh_log_cal;
close $fh_log_Xref;

__END__
