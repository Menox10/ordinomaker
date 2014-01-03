#
# Name: lib_hash.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

# initNode(string, string)
# Initalisation d'un Node
# global var : %Hsched
# return	(void)
sub initNode {
	my ($sched,$from) = @_ ;
	$Hsched{$sched}{'GRAPH'}		= "YES"		;
	$Hsched{$sched}{'CLUSTER'}	= "_MAIN"	;
	$Hsched{$sched}{'FROM'}	= $from;
}

# initLegende()
# Initalisation nodes/cluster légende
# # var globale : %Hsched $cDate
# return	(void)
sub initLegende {
	if ( $legend eq "no" ) { return() }
	
	my $legende = '_LEGENDE_'	;
	initNode($legende, "legende");
	$Hsched{$legende}{'CF'}						= "Carryforward"		;
	$Hsched{$legende}{'EVERY'} 				= "Cyclique"				;
	$Hsched{$legende}{'DESCRIPTION'}	= "Description JS"	;
	$Hsched{$legende}{'OUTFILE'}			= "Outfile"					;
	$Hsched{$legende}{'CLUSTER'}			= "_INFO_"					;
	$Hsched{$legende}{'ON'}						=	"ON"							;
	$Hsched{$legende}{'EXCEPT'}				=	"EXCEPT"					;
	$Hsched{$legende}{'AT'}						=	"\@0000-9999 ACT"	;
	$Hsched{$legende}{'NEEDS'}				=	"NEEDS Token"			;
	$Hsched{$legende}{'OPENS'}				=	"Open File"				;
	push(@{$Hsched{$legende}{'JOBS'}}	,	"Jobs (Recovery)");

	my $creation = $cpuName	;
	initNode($creation,"legende");
	# push(@{$Hsched{$creation}{'ON'}}, split(/T/,$cDate));
	$Hsched{$creation}{'CLUSTER'}	= "_INFO_"						;
	$Hsched{$creation}{'CF'}			= "CF"								;
}

# setCluster()
# CLUSTER : Ajout de %Hcluster -> %Hsched
# var globale : %Hsched %Hcluster
# return	(void)
sub setCluster {
	my ($sched,$key) = "";
	
	# Definition du format CLUSTER_ERROR
format CLUSTER_ERROR =							
Err @>>>>>>>>> : Defini dans => @<<<<<<<< n'existe pas !!!
$sched, $key
.
	$~ = "CLUSTER_ERROR";
	
	# Positionne le cluster pour chaque Jobstream(dans %Hsched)
	for $key ( sort keys %Hcluster ) {
		foreach ( @{$Hcluster{$key}{'addConfFile'}} ) {
			$sched = uc($_);
			if ( ! $Hsched{$sched} ) { write; next; }
			next if ( $Hsched{$sched}{'CLUSTER'} ne "_MAIN" ) ;
			$Hsched{$sched}{'CLUSTER'} = $key;
		}
	}
}

# setNext()
# NEXT (l'inverse du FOLLOWS) : Ajout dans %Hsched
# var globale : %Hsched
# return	(void)
sub setNext {
	my $key;
	
	# possitionne NEXT pour chaque FOLLOWS dans %Hsched
	for $key ( keys %Hsched ) {
		if ( $Hsched{$key}{'FOLLOWS'} ) {
			foreach ( @{$Hsched{$key}{'FOLLOWS'}} ) { 
				my $sched = uc($_);
				if ( ! $Hsched{$sched} ) { initNode($sched,"Follows"); }
				push(@{$Hsched{$sched}{'NEXT'}}, $key);
			}
		}
		
		# possitionne NEXT pour chaque VFOLLOWS dans %Hsched
		if ( $Hsched{$key}{'VFOLLOWS'} ) {
			my @vfollows = split( ";" , $Hsched{$key}{'VFOLLOWS'} );
			foreach ( @vfollows ) {
				my $sched = uc($_);
				if ( ! $Hsched{$sched} ) { initNode($sched,"vFollows"); }
				push(@{$Hsched{$sched}{'NEXT'}}, $key);
			}
		}
	}
}

# setConfFile()
# CONF FILE : Ajout dans %Hsched & %Hcluster
# global var : $Hsched %Hcluster
# return	(void)
sub setConfFile {
	my ($file) = @_ ;
	my ($ref,$key,$value,$message) = "";
	
format ADDCONF_LABEL =							
@>>>>>>>>>>>>> : @<<<<<<<<<< => @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$ref, $key, $message
.
	$~ = "ADDCONF_LABEL";

	open my $fh_confFile, '<:encoding(cp1252)', $file or die $!;
	while ( my $line = <$fh_confFile> ) {
		next if ( $line =~ m /^$|^#/ );
		
		($ref,$key,$value) = splitLine("$line");
		
		# Si CLUSTER
		if ( $ref eq "CLUSTER" ) {
			$message = "Ajout Cluster";
			push(@{$Hcluster{$key}{'addConfFile'}}, split(/;/, $value));
			write;
			next;
		} else {
			if ( $key eq "VFOLLOWS" ) { $value = uc($value); }
			# Si Fonction non prise en charge
			if (	$key ne "VFOLLOWS"		&& 
						$key ne "OUTFILE"			&&
						$key ne "DESCRIPTION" && 
						$key ne "GRAPH" 			&&
						$key ne "INFO" 	) {
				$message = "!!! Non prise en charge !!!";
				write;
				next;
			}
			# Si nouveau jobstream
			elsif ( ! $Hsched{$ref} ) { 
				$message = "Ajout Jobstream" ;
				write;
				initNode($ref,"Conf");	
			}
			# Si fonction deja defini
			elsif ( $Hsched{$ref}{$key} && $key ne "GRAPH" ) { 
				$message = "Deja defini, non prise en compte !!!" ;
				write;
				next ; 
			}
			
			# Ajout final
			if ( $key eq "OUTFILE") {
				@{$Hsched{$ref}{$key}} = split(";", $value) ;
			} else {
				$Hsched{$ref}{$key} = $value ;
			}
			$message = "Ajout Valeur " . lc($key) ; 
			write;
		}
	}
	close $fh_confFile or die $!;
}

# setSchedFiles(string, string)
# FILES SCHEDS : Ajout dans %Hsched
# global var : $Hsched
# return	(void)
sub setSchedFiles {
	my ($cpu, $dir) = @_;

	opendir (DIR, $dir) or die $!;

	# pour chque fichier jobstream 
	while (my $file = readdir(DIR)) {
		my $sched;
		($sched = $file ) =~ s/.txt//;
		my $fh_sched;
		next if ($file =~ m/^\.|head.txt/);
		my $on;
		my $except = "";
		my $at = "";	
		my $flag = 0;
	
		initNode($sched,"Main");
		
		# Injection du fichier schedule dans %Hsched
		open $fh_sched, '<:encoding(utf-8)', "$dir/$file" or die $!;
		while ( my $line = <$fh_sched> ) {
			if ( $flag == 0 ) { 
				# Jobstream
				if ( $line =~ "\^:\$" ) 			{ $flag = 1; next; }
				if ( $line =~ m/^ON / )				{ push(@{$Hsched{$sched}{'ON'}}, 			RegExpOnExcept("$line")); }
				if ( $line =~ m/^EXCEPT / )		{ push(@{$Hsched{$sched}{'EXCEPT'}},	RegExpOnExcept("$line")); }
				if ( $line =~ m/^FOLLOWS / )	{ push(@{$Hsched{$sched}{'FOLLOWS'}},	RegExpFollows("$line","$cpu")); }
				if ( $line =~ m/^OPENS? / )		{ push(@{$Hsched{$sched}{'OPENS'}},		RegExpOpens("$line")); }
				if ( $line =~ m/^AT |^UNTIL |^ONUNTIL / )	{ push(@{$Hsched{$sched}{'AT'}},	RegExpAt("$line")); }
				if ( $line =~ m/^DESCRIPTION/ )	{ chomp($line) ; $Hsched{$sched}{'DESCRIPTION'} = $line ; }
				if ( $line =~ m/^CARRYFORWARD/ )	{ $Hsched{$sched}{'CF'} = "CF"; }
			} else {
				# Job
				if ( $line =~ m/^#/ ) { next ; }
				if ( $line =~ "\^END\$" ) 	{ last; }
				if ( $line !~ m/^FOLLOWS |^NEEDS |^OPENS |^EVERY |^UNTIL |^AT / ) { push(@{$Hsched{$sched}{'aJOBS'}}, RegExpMain("$line")); }
				if ( $line =~ m/^AT |^UNTIL |^ONUNTIL / )	{ push(@{$Hsched{$sched}{'AT'}},	"(+ " . RegExpAt("$line") . ")" ); }
				push(@{$Hsched{$sched}{'JOBS'}}, RegExpMain("$line"));
			}
			# Commun
			if ( $line =~ m/^EVERY / ) { push(@{$Hsched{$sched}{'EVERY'}}, RegExpMain("$line")) }
			if ( $line =~ m/^NEEDS / ) { push(@{$Hsched{$sched}{'NEEDS'}}, RegExpNeeds("$line")) }
		}
		close $fh_sched or die $!;
	}
	closedir(DIR);
}

# setJobsHash(string)
# Injection du fichier Jobs dans %Hjobs
# global var : %Hjobs 
# return	(void)
sub setJobsHash {
	my ($file) = @_ ;
	my $fh_jobs;
	my $job = "Head";
	my $i = 0;
	
	open $fh_jobs, '<:encoding(cp1252)', $file or die $!;
	
	while ( my $line = <$fh_jobs> ) {
		# si ligne commance par ^Workstation on saute les deux suivantes
		if ( $line =~ /^Workstation / ) { $i = 2 ; next ;} 
		if ( $i != 0 ) { --$i ; next ;}
		next if ( $line =~ m/^$/ );
		
		# Nom du job courant
		if ( $line =~ m/^[0-9,a-z,A-Z,_]+\#[0-9,a-z,A-Z]+/)  { 
			$job = RegExpMain("$line");
		}
		
		if ( $job ne "Head" ) { 
			$Hjobs{$job}{'DEF'} .= $line;
			
			$line = RegExpMain($line);
			
			if ($line =~ /^RECOVERY/ ) {
				(my $recovery = $line ) =~ s/.+ (\w\w\w\w).*/$1/g;
				$Hjobs{$job}{'RECOVERY'} = $recovery;
			}
			
			if ($line =~ /^AFTER/ ) {
				(my $after = $line ) =~ s/AFTER (.+)/$1/g;
				$Hjobs{$job}{'AFTER'} = $after;
				if ( ! $Hsched{$after} ) { initNode($after, "after") }
			}
		}
	}
	close $fh_jobs or die $!;
}

# writeJobsInSched(string)
# Injection des jobs dans les fichiers Jobstreams
# global var : %Hsched %Hjobs 
# return	(void)
sub writeJobsInSched {
	my ($dir) = @_;
	my $sched;
	my $fh_sched;

	# Pour chaque fichier Jobstream
	opendir (DIR, $dir) or die $!;
	while (my $file = readdir(DIR)) {
		next if ($file =~ m/^\.|head.txt/);
		($sched = $file ) =~ s/.txt//;
		
		open $fh_sched, '>>:encoding(utf-8)', "$dir/$file" or die $!;
		
		# pour chaque aJOBS : injecte la definition dans le ficheir Jobstream
		foreach ( @{$Hsched{$sched}{'aJOBS'}} ) {
			print {$fh_sched} "\n-------------------------------------------------\n";
			print {$fh_sched} ( ( $Hjobs{$_}{'DEF'} ) ? 
														$Hjobs{$_}{'DEF'}  : 
														"$_  : Non trouve dans la def. des jobs"
												) ;
		}
		close $fh_sched or die $!;
	}
	
	closedir(DIR);
}

# setConvertFreq(string)
# Injection dans %Hconvfreq fichier convertFreq.conf
# global var : %Hconvfreq
# return	(void)
sub setConvertFreq {
	my $file = shift;
	my ($key, $value) ;
	
	open $fh, '<', $file or die;
	
	while (my $line = <$fh>) {
		next if ( $line =~ /^$|^#/);
		($key, $value) = split(/=>/, $line);
		$key		= RegExpMain($key);
		$value	= RegExpMain($value);
		$Hconvfreq{$key} = $value;
	}
}

1;
