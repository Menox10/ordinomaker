#
# Name: lib_link.pl
# 
# SVN Information:
# $Revision$
# $Date$
#


# set_link_after()
# relation : after
# global var : %Hsched %Hjobs
# return	(void)
sub set_link_after {
	for my $sched ( keys %Hsched ) {
		next if ( ! $Hsched{$sched}{'JOB_INC'} );
		
		my (@c_after, @t_after);
		
		foreach ( @{$Hsched{$sched}{'JOB_INC'}} ) {
			if( $Hjobs{$_} && $Hjobs{$_}{'AFTER'} ) {
				my $after = $Hjobs{$_}{'AFTER'};
				$after =~ s/${cpuName}#//g;
				push(@c_after, $after);
			}
		}

		@t_after = sort_unique_hash(@c_after);
		foreach ( @t_after ) { 
			push(	@{$Hlink{'AFTER'}},
						makeLink(	"$sched", "$_",  0,  0,  "darkolivegreen",  "AFTER" )
			);
		}
	}
}

# setLinks()
# follows 
# global var : %Hsched %Hjobs $maxSoloCol
# return	(void)
sub set_links {
	# maxSoloCol : 1 =< maxSoloCol >= 99 
	if ( $maxSoloCol < 1 || $maxSoloCol > 99 ) { 
		die "\$maxSoloCol=$maxSoloCol : valeur innattendu !";
	}
	# $count = Nombre de  Jobstream dans %Hsched
	my $count = keys %Hsched;
	
	# Calcul de maxSoloCol courant
	$maxSoloCol = int($count/$maxSoloCol);
	if ( $maxSoloCol < 6 ) { $maxSoloCol = 6 };
	
	print "\n-> Alignement vertical des noeuds solo : $maxSoloCol (maxSoloCol)\n";

	for my $sched ( keys %Hsched ) {
		my $cl = $Hsched{$sched}{'CLUSTER'};

		# Follows
		if ( $Hsched{$sched}{'FOLLOWS'} ) { 
			foreach ( @{$Hsched{$sched}{'FOLLOWS'}} ) {
				my ($dep,$job) = split('\.', $_);
				$job =~ s/@//;
				push(@{$Hlink{'FOLLOWS'}}, makeLink("$dep", "$sched", 0, 0, 0, "$job") );
			}
		}
		
		# Jfollows
		if ( $Hsched{$sched}{'JFOLLOWS'} ) { 
			foreach ( @{$Hsched{$sched}{'JFOLLOWS'}} ) {
				my ($dep,$job) = split('\.', $_);
				$job =~ s/@//;
				push(@{$Hlink{'JFOLLOWS'}}, makeLink("$dep", "$sched", 0, 0, "blue4", "$job") );
			}
		}
		
		# Vfollows
		if ( $Hsched{$sched}{'VFOLLOWS'} ) {
			foreach ( @{$Hsched{$sched}{'VFOLLOWS'}} ) {
				push(@{$Hlink{'VFOLLOWS'}},	makeLink(	"$_", "$sched", "$vfo_arrowhead", "$vfo_style", "$vfo_color", 0) );
			}
		}

		# Solo
		if (	! $Hsched{$sched}{'FOLLOWS'} &&
					! ( $Hsched{$sched}{'JFOLLOWS'} && $Opt{'JFOLLOWS'} ) && 
					! $Hsched{$sched}{'VFOLLOWS'} &&
					! $Hsched{$sched}{'NEXT'} && 
					$Hsched{$sched}{'FROM'} =~ /main/) {
					
			if (	( ! $Hcluster{$cl}{'ArnaqueFollows'} ) || 
						( $Hcluster{$cl}{'count'} >= $maxSoloCol ) ) { 
				$Hcluster{$cl}{'ArnaqueFollows'} = $sched;
				$Hcluster{$cl}{'count'} = 1;
			} else {
				my $c_sched = $Hcluster{$cl}{'ArnaqueFollows'};
				push(@{$Hlink{'SOLO'}},
							makeLink("$c_sched", "$sched", "none", 0, "none", 0)
						);
				$Hcluster{$cl}{'ArnaqueFollows'} = $sched;
				++$Hcluster{$cl}{'count'};
			
			}
		}
	}
}

# makeLink($source, $dest, $arrowhead, $style, $color, $xlabel)
# crée un lien entre deux noeuds
# global var : 
# return	(string) 
sub makeLink {
	my ($source, $dest, $arrowhead, $style, $color, $label) = @_;
	my $return;
	
	$return  = "\"$source\"";
	$return .= " -> ";
	$return .= "\"$dest\"";
	
	if ( $arrowhead || $style || $color || $label || $fontocolor ) {
		$return .=  " [ "; 
		if ($arrowhead)	{ $return .= "arrowhead=\"$arrowhead\"," }
		if ($style) 		{ $return .= "style=\"$style\"," }
		if ($color)			{ $return .= "color=\"$color\"" }
		if ($label)			{ $return .= "xlabel=\"$label\" fontsize=7 fontcolor=\"lightskyblue4\"" }
		$return .=  " ]"; 
	}
	$return .=  ";\n"; 
	
	return("$return");
}

1;
