#
# Name: lib_link.pl
# 
# SVN Information:
# $Revision$
# $Date$
#


# setLinkAfter()
# relation : after
# global var : %Hsched %Hjobs
# return	(void)
sub setLinkAfter {
	for my $sched ( keys %Hsched ) {
	
		my (@c_after, @t_after);
		
		foreach ( @{$Hsched{$sched}{'aJOBS'}} ) {
			if( $Hjobs{$_} && $Hjobs{$_}{'AFTER'} ) {
				my $after = $Hjobs{$_}{'AFTER'};
				$after =~ s/${cpuName}#//g;
				push(@c_after, $after);
			}
		}
		
		@t_after = sort_unique_hash(@c_after);
		foreach ( @t_after ) { 
			$linkAfter .= makeLink(	"$sched", "$_",  0,  0,  "darkolivegreen",  "AFTER" );
		}
	
	}
}

# setLinks()
# follows 
# global var : %Hsched %Hjobs $maxSoloCol
# return	(void)
sub setLinks {
	for my $sched ( keys %Hsched ) {
		next if ( $Hsched{$sched}{'GRAPH'} eq "NO" );
		my $cl = $Hsched{$sched}{'CLUSTER'};

		# Follows
		if ( $Hsched{$sched}{'FOLLOWS'} ) { 
			foreach ( @{$Hsched{$sched}{'FOLLOWS'}} ) { 
				$linkFollows .= makeLink("$_", "$sched", 0, 0, 0, 0);
			}
		}
		
	
		# Vfollows
		if ( $Hsched{$sched}{'VFOLLOWS'} ) {
			my @relationSplit = split( ";" , $Hsched{$sched}{'VFOLLOWS'} );
			foreach ( @relationSplit ) {
				$linkVfollows .= makeLink("$_", 
															"$sched", 
															"$vfo_arrowhead", 
															"$vfo_style", 
															"$vfo_color", 
															0 );
			}
		}
		
		# Solo
		if (	! $Hsched{$sched}{'FOLLOWS'} && 
					! $Hsched{$sched}{'VFOLLOWS'} && 
					! $Hsched{$sched}{'NEXT'}	) {
					
			if (	( ! $Hcluster{$cl}{'ArnaqueFollows'} ) || 
						( $Hcluster{$cl}{'count'} >= $maxSoloCol ) ) { 
				$Hcluster{$cl}{'ArnaqueFollows'} = $sched;
				$Hcluster{$cl}{'count'} = 1;
			} else {
				my $c_sched = $Hcluster{$cl}{'ArnaqueFollows'};
				$linkSolo .= makeLink("$c_sched", "$sched", "none", 0, "none", 0);
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
	
	if ( $arrowhead || $style || $color || $label) {
		$return .=  " [ "; 
		if ($arrowhead)	{ $return .= "arrowhead=\"$arrowhead\"," }
		if ($style) 		{ $return .= "style=\"$style\"," }
		if ($color)			{ $return .= "color=\"$color\"" }
		if ($label)			{ $return .= "xlabel=\"$label\" fontsize=7" }
		$return .=  " ]"; 
	}
	$return .=  ";\n"; 
	
	return("$return");
}

1;
