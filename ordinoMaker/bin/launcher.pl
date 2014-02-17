#
# Name: launcher.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use strict;
no warnings;
use File::Copy;
use File::Find;
use Archive::Tar;
use Cwd;
require("./ordinoMaker/lib/lib_regexp.pl");
use sigtrap 'handler' => \&myhand, 'INT';

open(STDERR,'>/dev/null') or die $! ;

# Varibale
my ($service, $file);
my (%Hservice, %Hfiles);
my @errNameFile;

my $selectFile = $ARGV[0];
open my $fh_select, '>:encoding(cp1252)', "ordinoMaker/tmp/$selectFile" or die $!;

my $docUG				= "ordinoMaker_UserGuide.doc";
my $docPath 		= "ordinoMaker/doc/$docUG";
my $getTwsFile	= 'ordinoMaker\bin\getTWSFile.cmd';
my $getEnvVPN		= 'ordinoMaker\bin\getEnvVPN.cmd';
my $sendTarMMC	= 'ordinoMaker\bin\sendTarMMC.cmd';

sub myhand {
	print "\n caught $SIG{INT} $$ (@_)\n";
	exit 1;
}

sub _choix {
	# use sigtrap 'handler' => \&myhand, 'INT';
	print "[q]: ";
	my $choix = <STDIN>;
	$choix = RegExpMain($choix);
	# choix
	if ( "$choix" eq "q" ) { exit 1 }
	
	return("$choix");
}

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

# get_tws()
# Recupérer fichier TWS
# global var : 
# return	(void)
sub get_tws {
		my ($vpn) = shift;

		if ( $vpn ne "Prod" && $vpn ne "Qualif" ) {
			print " -> VPN : $vpn\n";
			getSelect() ;
		}
		
		print "(VPN=$vpn) Quelle CPU ?";
		my $choix = _choix();
		my $cpu = uc($choix);

		if ( $cpu =~ m/\s|\W/ || $cpu eq "") {
			print "$cpu : non incorrect !\n\n";
			get_tws($vpn);
		} else {
			system("$getTwsFile $vpn $cpu");
		}
}

#create_tar ()
sub create_tar {
	my ($tar_file, $dir) = shift;
	my @files;
	my $dir = "_ordinogramme";
	my $cpwd = cwd();
	my $path = $cpwd . "/" . $dir ;
	my %HordinoDir;
	chdir($path);
	
	print " - Creation de l'archive : $tar_file ...\n";
	my $tar = Archive::Tar->new();
	find( sub {	push(@files, $File::Find::name) }, $service	);
	$tar->add_files( @files );
	
	foreach (@files) {
		my $ordinoDir = (split("/", $_))[1];
		$HordinoDir{$ordinoDir} = 1;
	}
	
	print " - Liste des repertoires archives:\n";
	print " "x3;
	foreach my $key (sort keys %HordinoDir) {
		next if ($key eq "");
		print "$key; ";
	}
	print "\n";
	
	# write a gzip compressed file
	chdir($cpwd);
	$tar->write( "$ENV{'Temp'}/$tar_file", COMPRESS_GZIP );
}

#send_tar ()
sub send_tar {
	my $dir = shift;
	if ( ! -d "_ordinogramme/$dir" ) {
		print "_ordinogramme/$dir inexistant !";
		return;
	}
	create_tar("$service.tar.gz", $dir);
	print " - Envoie du l'archive $service.tar.gz sur le serveur Ref\n";
	system("$sendTarMMC $service.tar.gz");
}

# serice - sub
sub print_service {
	my $count = keys %Hservice;
	my $i;
	
	print "Service :\n";
	
	for ( $i = 1; $i <= $count; $i++ ) {
		my 	$n = 1;
		if ( $i < 10 ) { $n = 2 }
		print " "x$n . "$i - $Hservice{$i}\n";
	}
}

sub build_service {
	my $i = 1;
	opendir (DIR_DF, "./_file_definition") or die $!;
	while (my $dir = readdir(DIR_DF)) {
		next if ( $dir =~ /^\./ );
		if ( -d "_file_definition/$dir" ) {
			$Hservice{$i} = $dir;
			$i++;
		}
	}
	closedir(DIR_DF);
}

sub set_service {

	my $count = shift;
	
	print "Merci de choisir votre service [1-$count]";
	my $choix = _choix();

	if ( ! $Hservice{$choix} ) {
		print "Choix incorrect\n";
	}
	return("$Hservice{$choix}");
}


# files - sub
sub build_files {
	my $i = 1;
	foreach my $key (keys %Hfiles) { delete $Hfiles{$key} }
	
	@errNameFile = ();
	
	opendir (DIR_S, "./_file_definition/$service") or die $!;
	
	while (my $f = readdir(DIR_S)) {
		( my $basename = $f ) =~ s/.txt$// ;
		
		next if ( $f !~ m/.txt$/ || $f =~ m/_jobs.txt$/);
		if ( $basename =~ m/\s|\W/ ) { 
			push(@errNameFile, $f);
			next;
		}

		$Hfiles{$i}{'FileName'} = $f ;
		if ( -e "_file_definition/$service/${basename}_jobs.txt" ) {
			$Hfiles{$i}{'jobFile'} = "+" ;
		} else {
			$Hfiles{$i}{'jobFile'} = "-" ;
		}
		$i++;
	}
	
	closedir(DIR_S);
}

sub print_files {
	my $count = keys %Hfiles;
	my $i;
	my $k = 20;
	
	print "\n" . "#"x40 ;
	print "\n"x2;
	print "Fichier(s) TWS de $service :\n";
	
	for ( $i = 1; $i <= $count; $i++ ) {
		my 	$n = 1;
		if ( $i < 10 ) { $n = 2 }
		my $l = ( $k - length("$Hfiles{$i}{'FileName'}"));
		print " "x$n . "$i - $Hfiles{$i}{'FileName'}" . " "x$l . "($Hfiles{$i}{'jobFile'} fic. jobs)\n";
	}
	print "\n";
	
	foreach (@errNameFile) {
			print " x - $_  => Nom incorrect (carc. alphanumerique uniquement)\n";
	}
	
	print "\n";
	print " 0 - Consulter le \"Guilde Rapide d'Utilisation\"\n";
	print " f - Recuperer fic. CPU (sur votre bureau)\n";
	print " r - Rafraichir\n";
	if ( $service eq "GA1-MMC" ) {
		print " p - Push des ordinos GA1-MMC sur le serveur de ref\n";
	}
}

sub set_files {
	my $count = shift;
	
	print "\nChoix fichier [0-" . $count . "][f][r]";
	if ($service eq "GA1-MMC") { print "[p]" }
	my $choix = _choix();
	
	# Rafraichir
	if ( "$choix" eq "r" ) {
		build_files();
		print_files();
		return;
	}
	
	# $choix = 0 : Ouverture de $docPath
	if ( "$choix" eq "0" ) {
		print "Ouverture de : " . $docUG ;
		copy("$docPath","$ENV{'Temp'}");
		system("CALL \"$ENV{'Temp'}/$docUG\"");
		if ( $? == 256 ) { print "\n => $docUG est deja ouvert\n" }
	}
	
	# $choix = f : Get TWS file
	if ( "$choix" eq "f" ) {
		my $vpn = envVpn();
		get_tws($vpn);
		return;
	}
	
	if ( "$choix" eq "p" || "$service" eq "GA1-MCC" ) {
		my $vpn = envVpn();
		if ($vpn ne "Qualif" ) {
				print "  Merci de connecter le VPN de Qualif\n";
		} else {
			send_tar("GA1-MMC");
		}
		return;
	}
	
	# Choix incorrect
	if ( ! $Hfiles{$choix} ) { 
		print " $choix - Choix incorrect";
		return;
	}
	
	$Hfiles{$choix}{'FileName'} =~ s/.txt$//;
	return("$Hfiles{$choix}{'FileName'}");
}

########
# Main #
########
print "ordinoMaker - Launcher v5\n\n";
print "q - Pour quitter a n'importe quel moment\n\n";

# service
if ( $ARGV[1] ) { 
	$service = $ARGV[1] 
} else {
	build_service();
	print_service();
	while ( ! $service ) { 
		my $count_service = keys %Hservice;
		$service = set_service($count_service);
	}
}

# file
build_files();
print_files();
while ( ! $file ) { 
	my $count_files = keys %Hfiles;
	$file = set_files($count_files);
}

# set fichier fh_select
print {$fh_select} "SET SERVICE=$service\n";
print {$fh_select} "SET FILE=$file\n";

print "\n";
print "  SERVICE = $service\n";
print "  FICHIER = $file\n";
print "\n";

close $fh_select or die $!;
close(STDERR) or die $!;

sleep 2;