#
# Name: launcher.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use strict;
no warnings;
require("./ordinoMaker/lib/lib_regexp.pl");

open(STDERR,'>/dev/null') or die $! ;

# Caught control c
$SIG{INT} = \&interrupt;
sub interrupt {
    print STDIN "Caught a control c!\n";
    exit 2;
}

# Varibale
my ($i, $j) = (1, 13);
my (%Hselect, %Hopt);
my @errorName;
my $choix;
my $JFExt				= "_jobs.txt";
my $docName	 		= "Guilde Rapide d'Utilisation";
my $docPath 		= "ordinoMaker/doc/UserGuide.doc";
my $getTwsFile	= 'ordinoMaker\bin\getTWSFile.cmd';
my $getEnvVPN		= 'ordinoMaker\bin\getEnvVPN.cmd';

open my $fh_setCpu, '>:encoding(cp1252)', "ordinoMaker/tmp/choixcpu.cmd" or die $!;
opendir (DIR, "./_file_definition") or die $!;

# envVpn()
# Recupérer l'env VPN : Qualif / Prod / KO
# global var : 
# return	(string)
sub envVpn {
	my $cr = "error";
	system($getEnvVPN);
	if ( $? == 0 	 ) { $cr = "KO" }
	if ( $? == 256 ) { $cr = "Prod" }
	if ( $? == 512 ) { $cr = "Qualif" }
	return("$cr");
}


# Permet l'affichage + selection des CPU
# global var : 
# return	(string,	string)
sub getSelect {
	if ($j) {
		# Va lire les fichier sous _file_definition
		while (my $file = readdir(DIR)) {
			( my $basename = $file ) =~ s/.txt$// ;
			
			# n'affiche pas les fichier jobs _jobs.txt
			if ( $file !~ m/.txt$/ || $file =~ m/${JFExt}$/) { next ;}
			# Met dans errorName les noms des fichiers incorrects
			if ( $basename =~ m/\s|\W/ ) { push(@errorName, $file);	next;	}
			
			my $k = ( $j - length("$file"));
			
			# Affiche : n° et nom de fichier 
			print " " . ( ( $i<10 ) ? " " . $i : $i ). " - " . $file;
			print " "x$k;
			# affiche si fichier jobs ou non 
			print ( ( -e "_file_definition/$basename$JFExt" ) ? 
										" (+ fic. jobs)" : " (- fic. jobs)"
						) ;
			print "\n";
	
			# Hselect : n° => file
			$Hselect{$i} = $file ;
			$i++;
		}
		closedir(DIR) or die $!;
		
		print "\n";
		foreach (@errorName) {
			print " x - $_  => Nom incorrect (carc. alphanumerique uniquement)\n";
		}
		print "\n";
		print "   0 - Consulter le \"" . $docName . "\"\n";
		print " f/F - Recuperer fic. CPU (sur votre bureau)\n";
		print " r/R - Rafraichir\n";
		print " q/Q - Quit\n";
		$j = 0 ;
		--$i;
	}
	
	print "\nChoix [0-" . $i . "][f/r/q] : ";
	$choix = <STDIN>;
	$choix = RegExpMain($choix);
	
	# Sortie
	if ( "$choix" eq "Q" || "$choix" eq "q" ) { exit 1 }
	if ( "$choix" eq "R" || "$choix" eq "r" ) { exit 2 }
	# Ouverture de $docPath si $choix = 0
	if ( "$choix" eq "0" ) {
		print "Ouverture de : " . $docName ;
		system("CALL \"$docPath\"");
		getSelect() ; 
	}
	
	if ( "$choix" eq "f" || "$choix" eq "F" ) {
		my $vpn = envVpn();
		if ( $vpn ne "Prod" && $vpn ne "Qualif") {
			print " -> VPN : $vpn\n";
			getSelect() ;
		}
		
		print "(VPN=$vpn) Quelle CPU ? (q/Q) : ";
		my $cpu = <STDIN>;
		$cpu = RegExpMain($cpu);
		$cpu = uc($cpu);
		
		if ( $cpu =~ m/\s|\W/ ) {
			print "$cpu : non incorrect !";
		} elsif ( "$cpu" eq "Q" || "$cpu" eq "q" ) {
		} else {
			system("$getTwsFile $vpn $cpu");
		}
		
		exit 2;
	}
	
	if ( "$choix" eq "0" ) {
		print "Ouverture de : " . $docName ;
		system("CALL \"$docPath\"");		getSelect() ; 
	}
	
	# si choix incorrect
	if ( ! $Hselect{$choix}) { 
		print " $choix - Choix incorrect";
		getSelect() ; 
	}
	
	$Hselect{$choix} =~ s/.txt$// ;
	return("$Hselect{$choix}", "$Hopt{uc($Hselect{$choix})}");
}


########
# Main #
########
print "Launcher v4\n\n";

my ($cpu , $params) = getSelect();
# ecrit dans le fichier fh_setCpu la CPU
print {$fh_setCpu} "SET CPU=$cpu\n";

close(STDERR) or die $! ;
close $fh_setCpu or die $! ;;
