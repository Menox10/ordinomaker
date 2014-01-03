#
# Name: lib_makeGvFile.pl
# 
# SVN Information:
# $Revision$
# $Date$
#


# setInNode($sched, $param, $size, $bold, $align, $bgcolor)
# création phrase compatible fic. graphviz
# global var : %Hsched %Hjobs $br $maxline $cpuName
# return	(string) 
sub setInNode {
	my ($sched, $param, $size, $bold, $align, $bgcolor) = @_ ;
	my $return = "" ;

	if ( defined($Hsched{$sched}{$param}) ) {
		my $value = "unknown";
		my $ref = \$Hsched{$sched}{$param};	

		if ( ($param ne "JOBS") && (ref($$ref) eq "ARRAY") ) {
			$value = join("$br", @{$Hsched{$sched}{$param}});
		} elsif ( ref($ref) eq "SCALAR" ) {
			$value = $Hsched{$sched}{$param};
		}	
	
		if ( $param eq "JOBS" ) {
			$value = "";
			foreach ( @{$Hsched{$sched}{$param}} ) {
				$value .= $_;
				if ( defined($Hjobs{$_}) && defined($Hjobs{$_}{'RECOVERY'}) ) {
					$value .= " ($Hjobs{$_}{'RECOVERY'})"
				}
				$value =~ s/$cpuName\#//g;
				$value .= $br;
			}
		}

		if ( $param eq "DESCRIPTION" ) {
			$Hsched{$sched}{'DESCRIPTION'} = RegExpDesc("$Hsched{$sched}{'DESCRIPTION'}");
			$value = addBrLine("$Hsched{$sched}{'DESCRIPTION'}", $br, $maxline);
		}

		$return = '<tr><td align="' . $align . '" ' 								;
		if ( $bgcolor ) { $return .= 'bgcolor="' . $bgcolor . '"' }	;
		$return .= '>'																							;
		$return .= '<font point-size="' . $size  . '">'							;
		$return .=  ( ( $bold ) ? '<B>' . $value . '</B>' : $value );
		$return .= "</font></td></tr>\n" 														;
	}
	return ($return);
}

# setInfoNode(string, string)
# Prise en compte des nodes INFO
# global var : 
# return	(string, string)
sub setInfoNode {
	my ($sched, $text) = @_;
	$text = RegExpDesc($text);
	$text = addBrLine($text, "\n", 25);

	my $nameInfoNode = "Info_" . $sched;
	
	my $node  = "\"$nameInfoNode\""						;
		 $node .= "[ "													;
		 $node .= "label=\"$text\" "						;
		 $node .= "shape=\"$ni_shape\" "				;
		 $node .= "color=\"$ni_color\" "				;
		 $node .= "fontname=\"$ni_fontname\" "	;
		 $node .= "fontsize=\"$ni_fontsize\" "	;
		 $node .= "margin=\"$ni_margin\" "			;
		 $node .= "]"														; 
		 
	my $link = makeLink("$nameInfoNode", "$sched","$li_arrowhead", "$li_style", "$li_color", 0);

	return("$node", "$link");
}

# setNodeclusterRelation($string, bool($simple), bool($full))
# Création des variables pour le fichier .gv
# global var : %Hsched %Hcluster $relation $mainColor
# option var : $jobs $maxSoloCol
# return	(void) 
sub setNodeclusterRelation {
	my ($dirName, $simple, $full) =	@_;
	my $sched;
	my $node;
	my $cl;
	my @cellule_size = ('6', '7' , '8' , '9', '15');
	my @legende_size = ('4', '4' , '5' , '6', '9');
	$linkInfo = "";
	
	for my $key ( keys %Hcluster ) {
		delete ($Hcluster{$key}{'NODE'});
		delete ($Hcluster{$key}{'ArnaqueFollows'});
		delete ($Hcluster{$key}{'count'});
	}

	# Creation du fichier graphviz - fichier ".gv"
	for $sched ( sort keys %Hsched ) {
		# Exception	
		next if ( $Hsched{$sched}{'GRAPH'} eq "NO" );

		# get Cluster du sched
		$cl = $Hsched{$sched}{'CLUSTER'};
		my $ref_size =  \@cellule_size;
		if ( $cl eq "_INFO_" ) { $ref_size =  \@legende_size }
		
		# nodeHead
		my ($nh_shape, $nh_fillcolor);
		if ( $Hsched{$sched}{'FROM'} eq "Main" ) {
			$nh_shape 		= $nh_shape_main			;
			$nh_fillcolor = $nh_fillcolor_main	;
		} else {
			$nh_shape 		= $nh_shape_other			;
			$nh_fillcolor = $nh_fillcolor_other	;
		}

		my	$nodeHead  = "[ ";
				$nodeHead .= "fontname=\"$nh_fontname\" "				;
				$nodeHead .= "penwidth=$nh_penwidth "						;
				$nodeHead .= "shape=\"$nh_shape\" "							;
				$nodeHead .= "fillcolor=\"$nh_fillcolor\" "			;
				$nodeHead .= "style=\"$nh_style\" "							;
				$nodeHead .= "margin=\"$nh_margin\" "						;
				$nodeHead .= "\n"																;
				$nodeHead .= 'label =<<table '									;
				$nodeHead .= "border=\"$nh_border\" "						; 
				$nodeHead .= "cellborder=\"$nh_cellborder\" "		; 
				$nodeHead .= "cellpadding=\"$nh_cellpadding\" "	; 
				$nodeHead .= "cellspacing=\"$nh_cellspacing\" "	; 
				$nodeHead .= "bgcolor=\"$nh_bgcolor\" "					;
		
		# node
		$node  = "\"$sched\""	;
		$node .= $nodeHead		;
		$node .= (( -e "$dirName/Jobstream/$sched.txt" ) 
								? " TITLE=\"$sched\n\n\n$sched\" HREF=\"./Jobstream/$sched.txt\" >" 
								: " >") ;	

		# node : cell Shed
		$node .= "\n<tr><td bgcolor=\"";
		$node .= ( $Hsched{$sched}{'CF'} ) ? "orangered" : "azure2";
		$node .= '" align="center"><font color="black"';
		$node .= " point-size=\"$ref_size->[4]\"><B>";
		$node .= $sched;
		$node .= "</B></font></td></tr>\n";
		
		# node : other cells
		if ( ! $simple ) {
			#											$sched,	$param	  		,$size						,$b, $align  	, $bgcolor
				$node .= 	setInNode($sched, "DESCRIPTION"	,"$ref_size->[0]" ,1,  "left"		, 0						);
				$node .= 	setInNode($sched, "EVERY"				,"$ref_size->[1]" ,1,  "center"	, "yellow"		);
				$node .= 	setInNode($sched, "ON"					,"$ref_size->[3]" ,1,  "center"	, 0						);
				$node .= 	setInNode($sched, "EXCEPT"			,"$ref_size->[2]" ,0,  "left"		, 0						);
				$node .= 	setInNode($sched, "AT"					,"$ref_size->[2]" ,0,  "left"		, 0						);
				$node .= 	setInNode($sched, "NEEDS"				,"$ref_size->[1]" ,1,  "center"	, "orange"		);
				$node .= 	setInNode($sched, "OPENS"				,"$ref_size->[2]" ,0,  "left"		, "white:navy");
				$node .= 	setInNode($sched, "OUTFILE"			,"$ref_size->[2]" ,0,  "right"	, "navy:white");
			if ($full) {					                                             
				$node .= 	setInNode($sched,	"JOBS"				,"$ref_size->[2]" ,0 ,  "left"	, 0						);
			}                                                                  
		}
		
		# node end
		$node .= "</table>> ];";
		
		# Def du cluster graph + color font
		$Hcluster{$cl}{'NODE'} .= $node . "\n";
		
		# INFO node
		if ( $Hsched{$sched}{'INFO'} ) {
			my ($infoNode, $infoLink) = setInfoNode("$sched", "$Hsched{$sched}{'INFO'}");
			$Hcluster{$cl}{'NODE'} .= $infoNode . "\n";
			$linkInfo .= $infoLink;
		}
	}
}

# setClusterColor()
# Defini les bgcolor des clusters
# global var : %Hcluster @color
# return	(void) 
sub setClusterColor {
	my $countColor = 0 ;

	for my $cl (keys %Hcluster) {
		if ( $cl eq "_MAIN" || $cl eq "_INFO_" ) {
			$Hcluster{$cl}{'BGCOLOR'} = $mainColor;
		} else {
			$Hcluster{$cl}{'BGCOLOR'} = $color[$countColor] ;
			++$countColor;
		}
	}
}

# writeVgFile($string)
# Ecriture du fichier .gv
# global var : %Hcluster $relation $mainColor $cpuName
# return	(void) 
sub writeVgFile {
	my ($file) = @_;
	my $clusterName;
	
	my $glabel = "\n\nCrée le ";
		$glabel .= $cDate;
		$glabel .= " par ";
		$glabel .= $ENV{"USERNAME"};
		$glabel .= "\nLBP GA1-CRR(MEE)";
	
	# graphHead : gh_
	my $graphHead  = "digraph {\n"									;
		 $graphHead .= "graph [ "											;
		 $graphHead .= "bgcolor=\"$mainColor\" "			;
		 $graphHead .= "fontsize=$gh_fontsize "				;		 
		 $graphHead .= "splines=$gh_splines "					;		
		 $graphHead .= "overlap=$gh_overlap "					;		
		 $graphHead .= "];\n"													;
		 $graphHead .= "ratio=\"$gh_ratio\";\n"				;
		 $graphHead .= "nodesep=$gh_nodesep;\n"				;
		 $graphHead .= "ranksep=$gh_ranksep;\n"				;
		 $graphHead .= "labelloc=\"$gh_labelloc\";\n"	;
		 $graphHead .= "label=\"$glabel\";\n"			;
		 _add_carac(\$graphHead, "\n");		

	open my $fh_vg, '>:encoding(utf-8)', $file or die $!; 

	# Debut de fichier
	print {$fh_vg} $graphHead . "\n";
	
	# cluster MAIN
	if ( $Hcluster{'_MAIN'}{'NODE'} ) { 
		print {$fh_vg} "$Hcluster{'_MAIN'}{'NODE'}";
	}

	# cluster autre
	for $clusterName ( sort keys %Hcluster ) {
		my $cl_Underscore;
		my $cl_def;
		( $cl_Underscore = $clusterName ) =~ s/[ \\\/"-.]/_/g;
		
		next if ( $clusterName eq "_MAIN"  ) ;
		next if ( ! $Hcluster{$clusterName}{'NODE'} );
		
		$cl_def  = "\nsubgraph cluster";
		$cl_def .= $cl_Underscore;
		$cl_def .= " {\n";
		$cl_def .= "labelloc=\"$cl_labelloc\";\n";
		$cl_def .= "fontsize=$cl_fontsize;\n";
		$cl_def .= 'bgcolor="' . $Hcluster{$clusterName}{'BGCOLOR'} . "\";\n";
		$cl_def .= "$Hcluster{$clusterName}{'NODE'}";
		if ( $cl_Underscore eq "_INFO_") { $cl_Underscore = "" }
		$cl_def .= "\nlabel = \"" . $cl_Underscore . "\" ;";
		$cl_def .= "\n}\n";
		
		print {$fh_vg} $cl_def;
	}
	
	# link
	if ( $linkFollows	)		{ print {$fh_vg} $linkFollows		}
	if ( $linkVfollows)		{ print {$fh_vg} $linkVfollows	}
	if ( $linkAfter		)		{ print {$fh_vg} $linkAfter			}
	if ( $linkSolo		)		{ print {$fh_vg} $linkSolo			}
	if ( $linkInfo		)		{ print {$fh_vg} $linkInfo			}
	
	# fin de fichier
	print {$fh_vg}  "\n}\n";

	close $fh_vg or die $!;
}	

1;