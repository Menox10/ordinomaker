#
# Name: lib_hash.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use Carp qw( croak );

# initNode($sched,$from)
# Initalisation d un Node
# global var : %Hsched
# return	(void)
sub initNode {
	my ($sched,$from) = @_ ;
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
	$Hsched{$legende}{'CARRYFORWARD'}	= "Carryforward"		;
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
	$Hsched{$creation}{'CLUSTER'}	= "_INFO_"						;
	$Hsched{$creation}{'CF'}			= "CF"								;
}

# set_sched($sched, $line)
# Initalisation d'un Node
# global var : %Hsched
# return	(void)
sub set_sched {
	my ($sched, $line) = @_;
	return if ( $line =~ /^#/ );
	my @split_line = split(/\s/, "$line");
	my $keyword = $split_line[0];
	if ( $keyword eq "UNTIL" ) { $keyword = "AT" }
	
	# initalisation sched from Main
	if ( $keyword eq "SCHEDULE" ) {
	 if ( ! $Hsched{$sched} ) {
		initNode($sched, "Main");
			return;
		} else {
			croak("\nERROR : $sched Declare plusieurs fois !!!\n");
		}
	}

	# Initalise la partie definition job
	if ( $keyword eq ":" ) { 
		$Hsched{$sched}{'j_flag'} = 1;
		return;
	}
	
	# si partie def. job
	if ( $Hsched{$sched}{'j_flag'} ) {
		# recovery
		if ( $chk_fjobs && $Hjobs{$line} ) { 
			push(@{$Hsched{$sched}{'JOB_INC'}}, $line);
			if ( $Hjobs{$line}{'RECOVERY'} ) {
				$line = $line . " ($Hjobs{$line}{'RECOVERY'})";
			}
		}
		# Si every
		if ( $keyword eq "EVERY" ) {
			my $every = regexpSwitcher($keyword, "$line");
			push(@{$Hsched{$sched}{$keyword}}, "$every");
		}
		# push dans Jobs
		push(@{$Hsched{$sched}{'JOBS'}}, "$line");
		
	# si partie def. sched
	} else {
		foreach ( @keywords ) {
			if ( $keyword eq $_ ) {
				$line = regexpSwitcher($keyword, "$line");
				push(@{$Hsched{$sched}{$_}}, "$line");
			}
		}
	}
}

# set_jobs(string)
# Injection du fichier Jobs dans %Hjobs
# global var : %Hjobs 
# return	(void)
sub set_jobs {
	my ($file) = @_ ;
	my $job ;
	my $i = 0;
	
	open my $fh_jobs, '<:encoding(cp1252)', $file or die $!;
	
	while ( my $line = <$fh_jobs> ) {
		# si ligne commance par ^Workstation on saute les deux suivantes
		if ( $line =~ /^Workstation / ) { $i = 2 ; next ;} 
		if ( $i != 0 ) { --$i ; next ;}
		next if ( $line =~ m/^$/ );
		
		# Nom du job courant
		if ( $line =~ m/^[0-9,a-z,A-Z,_]+\#[0-9,a-z,A-Z]+/)  { 
			$job = RegExpMain("$line");
		}
		
		if ( $job ) {
			$Hjobs{$job}{'DEF'} .= $line;

			$line = RegExpMain($line);
			
			if ($line =~ /^RECOVERY/ ) {
				(my $recovery = $line ) =~ s/.+ (\w\w\w\w).*/$1/g;
				$Hjobs{$job}{'RECOVERY'} = $recovery;
			}
			
			if ($line =~ /^AFTER/ ) {
				(my $after = $line ) =~ s/AFTER (.+)/$1/g;
				$after =~ s/$cpuName#//;
				$Hjobs{$job}{'AFTER'} = $after;
				if ( ! $Hsched{$after} ) { initNode($after, "AFTER") }
			}
		}
	}
	close $fh_jobs or die $!;
}

# set_next()
# NEXT (l'inverse du (V)FOLLOWS) : Ajout dans %Hsched
# var globale : %Hsched
# return	(void)
sub set_next {
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
			foreach ( @{$Hsched{$key}{'VFOLLOWS'}} ) { 
				my $sched = uc($_);
				if ( ! $Hsched{$sched} ) { initNode($sched,"vFollows"); }
				push(@{$Hsched{$sched}{'NEXT'}}, $key);
			}
		}
	}
}

# set_conf()
# CONF FILE : Ajout dans %Hsched & %Hcluster
# global var : $Hsched %Hcluster
# return	(void)
sub set_conf {
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
						$key ne "INFO" 	) {
				$message = "!!! Non prise en charge !!!";
				write;
				next;
			}
			# Si nouveau jobstream
			elsif ( ! $Hsched{$ref} ) { 
				$message = "Ajout Jobstream" ;
				write;
				initNode($ref,"CONF");	
			}
			# Si fonction deja defini
			elsif ( $Hsched{$ref}{$key} ) { 
				$message = "Deja defini, non prise en compte !!!" ;
				write;
				next ; 
			}
			
			# Ajout final
			if ( $key eq "INFO" ) {
				$Hsched{$ref}{$key} = $value ;
			} else {
				if ( $key eq "DESCRIPTION" ) { $value = regexpSwitcher($key, $value) }
				@{$Hsched{$ref}{$key}} = split(";", $value) ;	
			}
			$message = "Ajout Valeur " . lc($key) ; 
			write;
		}
	}
	close $fh_confFile or die $!;
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
	
	# Cluster si _MAIN et un seul ON
	for $sched ( keys %Hsched ) {
		if (	$Hsched{$sched}{'FROM'} eq "Main" && 
					$Hsched{$sched}{'CLUSTER'} eq "_MAIN" ) {
			if ( $Hsched{$sched}{'ON'} &&	@{$Hsched{$sched}{'ON'}} eq "1" ) {
				my $ON = $Hsched{$sched}{'ON'}[0];
	
				if (	$ON eq "REQUEST" || 
							$ON eq "SA" ||
							$ON eq "SU" ||
							$ON eq "SA,SU" ||
							$ON eq "DAILY" ||
							$ON eq "WORKDAY" )		{
					if ( $ON eq "SA,SU" ) { $ON = "week-end"}
					$Hsched{$sched}{'CLUSTER'} = $ON ; 
					$Hcluster{$ON} = ();
				}
			}
		}
	}
}

1;
__END__
