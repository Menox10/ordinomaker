#
# Name: lib_params.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

# load_params(string)
# fonction de lecture du fichier de parametres
# global var : 
# return	(void))
sub load_params {
	my ($file) = @_;
	my $key;
	my $value;

	open my $fh_params, '<',  $file or die $!;

	while ( <$fh_params> ) {
		chomp();	
		next if ( /^#/ ) ;
		next if ( /^$/ ) ;
		
		($key,$value) = split("=",$_);
		
		# Global
		if ( $key eq "color" 			) { our @color 			= split(/;/, $value) }
		if ( $key eq "mainColor"	)	{	our $mainColor	= $value 						 }
		if ( $key eq "br" 				)	{ our $br					= $value 						 }
		if ( $key eq "maxline"		)	{ our $maxline		= $value 						 }
		if ( $key eq "legend"			)	{ our $legend			= $value 						 }
		if ( $key eq "maxSoloCol"	)	{ our $maxSoloCol	= $value 						 }
		
		# nodeHead : nh_
		if ( $key eq "nh_fontname"	)	{ our $nh_fontname		= $value }
		if ( $key eq "nh_penwidth"	)	{ our $nh_penwidth		= $value }
		if ( $key eq "nh_style"			)	{ our $nh_style				= $value }
		if ( $key eq "nh_margin"		)	{ our $nh_margin			= $value }
		
		if ( $key eq "nh_border"			)	{ our $nh_border			= $value }
		if ( $key eq "nh_cellborder"	)	{ our $nh_cellborder	= $value }
		if ( $key eq "nh_cellpadding"	)	{ our $nh_cellpadding	= $value }
		if ( $key eq "nh_cellspacing"	)	{ our $nh_cellspacing	= $value }
		if ( $key eq "nh_bgcolor"			)	{ our $nh_bgcolor			= $value }
		
		if ( $key eq "nh_shape_main"			)	{ our $nh_shape_main			= $value }
		if ( $key eq "nh_fillcolor_main"	)	{ our $nh_fillcolor_main	= $value }		
		if ( $key eq "nh_shape_other"			)	{ our $nh_shape_other			= $value }		
		if ( $key eq "nh_fillcolor_other"	)	{ our $nh_fillcolor_other	= $value }
		
		# graphHead : gh_
		if ( $key eq "gh_fontsize" )	{ our $gh_fontsize	= $value }
		if ( $key eq "gh_splines"	 )	{ our $gh_splines		= $value }		
		if ( $key eq "gh_overlap"	 )	{ our $gh_overlap		= $value }		
		if ( $key eq "gh_ratio"		 )	{ our $gh_ratio			= $value }
		if ( $key eq "gh_nodesep"	 )	{ our $gh_nodesep		= $value }
		if ( $key eq "gh_ranksep"	 )	{ our $gh_ranksep		= $value }		
		if ( $key eq "gh_labelloc" )	{ our $gh_labelloc	= $value }
		
		# nodeInfo : ni_
		if ( $key eq "ni_shape"			)	{ our $ni_shape			= $value }		
		if ( $key eq "ni_color"			)	{ our $ni_color			= $value }
		if ( $key eq "ni_fontname"	)	{ our $ni_fontname	= $value }
		if ( $key eq "ni_fontsize"	)	{ our $ni_fontsize	= $value }		
		if ( $key eq "ni_margin"		)	{ our $ni_margin		= $value }
		# nodeInfo : li_
		if ( $key eq "li_arrowhead"	)	{ our $li_arrowhead	= $value }
		if ( $key eq "li_style"			)	{ our $li_style			= $value }		
		if ( $key eq "li_color"			)	{ our $li_color			= $value }
		
		# vfollows : vfo_
		if ( $key eq "vfo_arrowhead")	{ our $vfo_arrowhead	= $value }
		if ( $key eq "vfo_style"		)	{ our $vfo_style			= $value }		
		if ( $key eq "vfo_color"		)	{ our $vfo_color			= $value }
	
		# cluster : cl_
		if ( $key eq "cl_labelloc" )	{ our $cl_labelloc = $value }		
		if ( $key eq "cl_fontsize" )	{ our $cl_fontsize = $value }
	} 
}

1;