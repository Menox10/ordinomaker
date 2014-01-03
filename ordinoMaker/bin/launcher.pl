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

# Varibale

my ($i, $j) = (1, 13);
my (%Hselect, %Hopt);
my @errorName;
my $choix;
my $JFExt				= "_jobs.txt";
my $docName	 		= "Guilde Rapide d'Utilisation";
my $docPath 		= "ordinoMaker/doc/UserGuide.doc";

open my $fh_setCpu, '>:encoding(cp1252)', "ordinoMaker/tmp/choixcpu.cmd" or die $!;
opendir (DIR, "./_file_definition") or die $!;


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
		print "\n  0 - Consulter le \"" . $docName . "\"\n";
		print "\n q/Q - Quit";
		$j = 0 ;
		--$i;
	}
	
	print "\nChoix [0-" . $i . "] : ";
	$choix = <STDIN>;
	$choix = RegExpMain($choix);
	
	# Sortie
	if ( "$choix" eq "Q" || "$choix" eq "q" ) { print "\nSortie\n" ; exit 1}
	# Ouverture de $docPath si $choix = 0
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
print "Launcher v3\n\n";
my ($cpu , $params) = getSelect();
# ecrit dans le fichier fh_setCpu la CPU
print {$fh_setCpu} "SET CPU=$cpu\n";

close $fh_setCpu;
