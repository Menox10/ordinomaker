#
# Name: main.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use strict;
use warnings;
# no warnings 'uninitialized';
use File::Path;
use Getopt::Long;
require("./ordinoMaker/lib/lib_regexp.pl");
require("./ordinoMaker/lib/lib_hash.pl");
require("./ordinoMaker/lib/lib_log.pl");
require("./ordinoMaker/lib/lib_makeGvFile.pl");
require("./ordinoMaker/lib/lib_params.pl");
require("./ordinoMaker/lib/lib_link.pl");
use File::Path;

################################################################################
# Option
our $jobs;

GetOptions ("jobs"					=> \$jobs)
or die("Erreur dans les arguemnts !\n");
if ( ! $ARGV[0] ) {die("Merci de passer en paramètre le fichier d'entrée !\n")}

################################################################################
# !! Variables !!
my $source_file;
my $jobs_file;
my $dirName;

# Fichier d'entrée
$source_file = $ARGV[0];
if ( ! -e "_file_definition/$source_file" ) {
	die("$source_file : fichier entrant non present !\n");
}

# definition répertoire  
($dirName = $source_file) =~ s/\.txt$//i;
if (	$dirName =~ /ORDINOMAKER/i ) {
	die("\n => \"" . $dirName . "\" Non autorisee, sortie sans action ...\n\n");
}

# definition fichier de conf.
my $conf_file;
($conf_file = $source_file) =~ s/\.txt$/\.conf/;

# definition fichier jobs
($jobs_file = $source_file) =~ s/\.txt$/\_jobs\.txt/;

print "\n-> Fichier Source  = " . $source_file . "\n";
print "\tFic. Jobs  = " . ( ( -e "_file_definition/$jobs_file" ) ? 
																	"$jobs_file" : 
																	"! Non present ($jobs_file)"
													) . "\n" ;
print "\tFic. Conf  = " . ( ( -e "_conf/$conf_file" ) ? 
																	$conf_file : 
																	"Pas de fichier de conf"
													) . "\n";
print "\tRepertoire = " . $dirName . "\n";
print "\n" ;

# FH
my $fh_source;
my $fh_schedule;
# Hash
our ( %Hsched, %Hcluster, %Hjobs, %Hconvfreq, %ENV );
# Variable
my $i;
my $fichier_resultat	= 'head.txt';
our $cDate						= cDate();
our $cpuName;
our $maxSoloCol;
our ($linkFollows, $linkVfollows, $linkAfter, $linkSolo, $linkInfo);


################################################################################
# Chargement fichier parametres
load_params("./ordinoMaker/etc/ordinoMaker.conf");

#######################
# Programme Principal #
#######################
# Open File
open $fh_source, '<:encoding(cp1252)', "_file_definition/$source_file" or die $!;
################################################################################
#  Supp et creation repertorie de travail
print "-> Suppr & Creation du repertoire : \"$dirName\"\n";
rmtree("_ordinogramme/$dirName", 0, 1);
sleep 1;
mkpath("_ordinogramme/$dirName/Jobstream",0, 0775 );

################################################################################
# Création des fichiers sous CPU/Jobstream/*
# Split du fichier source en 1 fichier par schdule
print "\n-> Decoupe du fichier source $source_file\n";
$i = 0;
open $fh_schedule, '>:encoding(utf-8)', "_ordinogramme/$dirName/Jobstream/$fichier_resultat" or die $!;

while ( my $line = <$fh_source> ) {
	next if ( $line =~ m/^$/ );
	
	if ( $line =~ m/^END$/ ) { print {$fh_schedule} $line; $i = 0 ; next ;}	
	
	if ( $line =~ m{^SCHEDULE })  {
		$i = 1;
		close $fh_schedule or die $!;
		
		# Definition cpuName et schedName
		my @splitLine = split(/\s|#/ , $line);
		if ( ! $cpuName ) { 
			$cpuName = $splitLine[1];
			print "\tDetection CPU = \"$cpuName\"\n";
		}
		my $schedName = uc($splitLine[2]);
		$schedName =~ RegExpMain($schedName);
		$fichier_resultat = "$schedName.txt";
		# print "$schedName.txt\n";

		if  ( -e "_ordinogramme/$dirName/Jobstream/$fichier_resultat" ) {
			print "Err   $schedName : Declare plusieurs fois !\n";
		}
		open $fh_schedule, '>:encoding(utf-8)', "_ordinogramme/$dirName/Jobstream/$fichier_resultat" or die $!;
		# print "Creation : \"$fichier_resultat\"\n";
	}
	$line =~ s/^\s+|\s+$//g;
	# Ecriture dans le fichier resultat
	if ( $i == 1  ) { print {$fh_schedule} $line . "\n";	}
}

close $fh_source or die $!;
close $fh_schedule or die $!;

################################################################################
# initialisation du hash %Hconvfreq
setConvertFreq("ordinoMaker/etc/convertFreq.conf");

################################################################################
# MAIN FILE : Ajout dans %Hsched
setSchedFiles($cpuName, "_ordinogramme/$dirName/Jobstream");

################################################################################
# maxSoloCol
# 1 =< maxSoloCol >= 99 
if ( $maxSoloCol < 1 || $maxSoloCol > 99 ) { 
	die "\$maxSoloCol=$maxSoloCol : valeur innattendu !";
}
# $count = Nombre de  Jobstream dans %Hsched
my $count = keys %Hsched;

# Calcul de maxSoloCol courant
$maxSoloCol = int($count/$maxSoloCol);
if ( $maxSoloCol < 6 ) { $maxSoloCol = 6 };

print "\n-> Alignement vertical des noeuds solo : $maxSoloCol (maxSoloCol)\n";

################################################################################
# CONF FILE : Ajout du ficher de _conf dans %Hsched
if ( -e "_conf/$conf_file" ) { 
	print "\n-> Prise en compte du fichier de conf \"" . $conf_file . "\"\n" ;
	setConfFile("_conf/$conf_file");
}
# CLUSTER : Ajout de %Hcluster -> %Hsched
initLegende();
setCluster();
# NEXT (l'inverse du FOLLOWS) : dans %Hsched
setNext();
# Création des relations
setLinks();

################################################################################
# Ecriture des jobs si fichier jobs
if ( -e "_file_definition/$jobs_file" ) {
	print "\n-> Prise en compte fichier jobs \"$jobs_file\"\n";
	setJobsHash("_file_definition/$jobs_file");
	writeJobsInSched("_ordinogramme/$dirName/Jobstream");
	setLinkAfter();
}

################################################################################
# Création des fichiers .vg
print "\n-> Creation des fichiers .gv :\n";

setClusterColor();

print "\tsimple   : ${dirName}_simple.gv\n";
	setNodeclusterRelation("$dirName", 1, 0);
	writeVgFile("ordinoMaker/tmp/${dirName}_simple.gv");

print "\tstandard : $dirName.gv\n";
	setNodeclusterRelation("$dirName", 0, 0);
	writeVgFile("ordinoMaker/tmp/$dirName.gv");
	
print "\tcomplet  : ${dirName}_complet.gv\n";
	setNodeclusterRelation("$dirName", 0, 1);
	writeVgFile("ordinoMaker/tmp/${dirName}_complet.gv");

################################################################################
# Création du .xls file
my $log;
$log = makeXlsFile("_ordinogramme/$dirName/$dirName.xls", $dirName);
print "\n-> Creation du fichier $dirName.xls : $log";
print "\n";

################################################################################
# print des HASH dans la log file.log
writeLog("ordinoMaker/tmp/$dirName.log");
