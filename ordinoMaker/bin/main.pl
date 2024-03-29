﻿#
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
require("./ordinoMaker/lib/lib_hash.pl");
require("./ordinoMaker/lib/lib_link.pl");
require("./ordinoMaker/lib/lib_makeGvFile.pl");
require("./ordinoMaker/lib/lib_regexp.pl");
require("./ordinoMaker/lib/lib_utils.pl");


################################################################################
# Variables Locale
my $service			= $ARGV[0];
my $source_file	= $ARGV[1];
my $jobs_file;
my $dirName;
my $conf_file;
($dirName = $source_file) =~ s/\.txt$//i;
($conf_file = $source_file) =~ s/\.txt$/\.conf/;
($jobs_file = $source_file) =~ s/\.txt$/\_jobs\.txt/;

# FH
my $fh_source;
my $fh_sched;

# Variable Globale
our ( %Hsched, %Hcluster, %Hjobs, %Hlink, %Hconvfreq, %ENV, %Opt );
our ($chk_fjobs, $chk_fconf ) = 0;
our $cDate = cDate();
our $cpuName;

################################################################################
# UTLIS
# Controle de l environnement
checkEnv(	"_file_definition/$service/$source_file",
					"_file_definition/$service/$jobs_file", 
					"_conf/$conf_file", 
					"_ordinogramme/$service/$dirName");
# Chargement des options : %Opt
load_opt("./ordinoMaker/etc/options.conf", "./ordinoMaker/etc/$service.conf");
# Chargement fichier parametres
load_params("./ordinoMaker/etc/ordinoMaker.conf");
# %Hconvfreq - Initialisation
setConvertFreq("ordinoMaker/etc/convertFreq.conf");

#######################
# Programme Principal #
#######################
# Open File
open $fh_source, '<:encoding(cp1252)', "_file_definition/$service/$source_file" or die $!;
################################################################################
#  Supp et creation repertorie de travail
print "-> Suppr & Creation du repertoire : \"_ordinogramme\\$service\\$dirName\"\n";
rmtree("_ordinogramme/$service/$dirName", 0, 1);
sleep 1;
mkpath("_ordinogramme/$service/$dirName/Jobstream",0, 0775 );

################################################################################
# Injection fichier source dans %Hsched
# Split du fichier source en 1 fichier/sched sous _ordinogramme/CPU/Jobstream/*
# Injection fichier jobs dans %Hjobs
print "\n-> Prise en compte et decoupe du fichier source \"$source_file\"\n";
my ($key, $cpu, $c_sched);
my $i = 0;
while ( my $line = <$fh_source> ) {
	next if ( $line =~ /^\s*$/ );
	chomp($line);
	trim(\$line);

	# ^END$ and close
	if ( $line =~ m/^END$/ ) { 
		print {$fh_sched} $line . "\n\n"; 
		$i = 0 ;
		
		if ( $Hsched{$c_sched}{'JOB_INC'} ) {
			foreach ( @{$Hsched{$c_sched}{'JOB_INC'}} ) {
				print {$fh_sched} "-------------------------------\n" . $Hjobs{$_}{'DEF'};
			} 
		}
		next;
	}	
	
	# ^SCHEDULE
	if ( $line =~ /SCHEDULE\s/ ) {
		$i = 1;
		if ( $fh_sched ) { close $fh_sched or die $!; }
		
		# Definition cpuName et c_sched
		($key, $cpu, $c_sched) = split(/\s|#/ , $line);
		if ( ! $cpuName ) {  
			$cpuName = $cpu;
			# Ecriture des jobs si fichier jobs
			if ( $chk_fjobs ) {
				print "   Prise en compte fichier jobs \"$jobs_file\"\n";
				set_jobs("_file_definition/$service/$jobs_file");
			}
			print "\tDetection CPU = \"$cpuName\"\n";
		}
		$c_sched = RegExpMain($c_sched);
		if ( $cpu ne $cpuName ) { 
			print "WAR\t$c_sched def sur cpu : $cpu\n";
			$c_sched= RegExpMain("$cpu#$c_sched");
		}

		# open
		open $fh_sched, '>:encoding(cp1252)', "_ordinogramme/$service/$dirName/Jobstream/$c_sched.txt" or die $!;
	}

	# Ecriture dans le fichier resultat
	if ( $i == 1  ) { 
		print {$fh_sched} $line . "\n";
		set_sched($c_sched, "$line");
	}
}

close $fh_source or die $!;
close $fh_sched or die $!;

################################################################################
# CONF FILE : Ajout du ficher de _conf dans %Hsched
if ( $chk_fconf ) { 
	print "\n-> Prise en compte du fichier de conf \"" . $conf_file . "\"\n" ;
	set_conf("_conf/$conf_file");
}

################################################################################
# Legende
initLegende();
# NEXT (l'inverse du (V)FOLLOWS) : dans %Hsched
set_next();
# CLUSTER : Ajout de %Hcluster -> %Hsched
setCluster();
# Definition couleurs des cluster
setClusterColor();
# Creation des relations
if ( $chk_fjobs ) { set_link_after() }
set_links();

################################################################################
# Création des fichiers .vg
print "\n-> Creation des fichiers .gv :\n";

print "\tsimple   : ${dirName}_simple.gv\n";
	buildNodes("$service/$dirName", 1, 0);
	writeVgFile("ordinoMaker/tmp/${dirName}_simple.gv", $service, 1);

print "\tstandard : $dirName.gv\n";
	buildNodes("$service/$dirName", 0, 0);
	writeVgFile("ordinoMaker/tmp/$dirName.gv", $service, 0);

print "\tcomplet  : ${dirName}_complet.gv\n";
	buildNodes("$service/$dirName", 0, 1);
	writeVgFile("ordinoMaker/tmp/${dirName}_complet.gv", $service, 0);

# Création du .xls file
my $log;
$log = makeXlsFile("_ordinogramme/$service/$dirName/$dirName.xls", $dirName);
print "\n-> Creation du fichier $dirName.xls : $log";
print "\n";

################################################################################
# print des HASH dans la log file.log
writeLog("ordinoMaker/tmp/$dirName.log", $service);	

