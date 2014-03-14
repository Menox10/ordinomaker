#
# Name: lib_utils.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use POSIX qw(strftime);
use Data::Dumper;
use Spreadsheet::WriteExcel;

# cDate()
# current date (YYYY-MM-DDTHH:MM:SS)
# global var : 
# return	(string) 
sub cDate {
	my $date = strftime "%Y%m%dT%H:%M:%S", localtime;
	# print $date;
	return($date);
}

# sort_unique_hash(array)
# sort unique array
# global var : 
# return	(%hash) 
sub sort_unique_hash {
	my %hash;
	@hash{@_} = ();
	return sort keys %hash;
}

# checkEnv($source_file, $jobs_file, $conf_file, $dirName)
# check et print de l environnement
# global var :
# return(void)
sub checkEnv {
	my ($source_file, $jobs_file, $conf_file, $dirName) = @_;
	
	# Check - Fichier jobstream
	if ( ! -e "$source_file" ) {
		die("$source_file : fichier source non present !\n");
	}
	
	if ( -e "$jobs_file" ) { $chk_fjobs = 1 }
	if ( -e "$conf_file" ) { $chk_fconf = 1 }
	
	# Print environnement
	print "\n-> Fichier Source  = " . $source_file . "\n";
	print "\tFic. Jobs  = " . ( ( $chk_fjobs ) ? 
																		"$jobs_file" : 
																		"! Non present ($jobs_file)"
														) . "\n" ;
	print "\tFic. Conf  = " . ( ( $chk_fconf ) ? 
																		$conf_file : 
																		"Pas de fichier de conf"
														) . "\n";
	print "\tRepertoire = $dirName";
	print "\n\n";

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

# load_params($file)
# fonction de lecture du fichier de parametres
# global var : 
# return	(void)
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
		if ( $key eq "keywords"			)	{ our @keywords			 = split(/;/, $value) }
		if ( $key eq "keywordStd"		)	{ our @keywordStd		 = split(/;/, $value) }
		if ( $key eq "keywordSimple")	{ our @keywordSimple = split(/;/, $value) }
		if ( $key eq "keywordFull"	)	{ our @keywordFull	 = split(/;/, $value) }
		
		if ( $key eq "color" 			) { our @color 			= split(/;/, $value) }
		if ( $key eq "mainColor"	)	{	our $mainColor	= $value 						 }
		if ( $key eq "br" 				)	{ our $br					= $value 						 }
		if ( $key eq "maxline"		)	{ our $maxline		= $value 						 }
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

sub load_opt {
	my ( $global, $service ) = @_;
	my $key;
	my $value;

	for ( $global, $service ) {
		if ( -f $_ ) {
			open my $fh_opt, '<',  $_ or die $!;
		
			while ( <$fh_opt> ) {
				chomp();	
				next if ( /^#/ ) ;
				next if ( /^$/ ) ;
				
				($key,$value) = split("=",$_);
				$Opt{$key} = $value;
			}
			
			close $fh_opt or die $!;
		}
	}
}

# dumperHash(%hash)
# recupére le dump d'un hash
# global var : 
# return	(string) 
sub dumperHash {
	my (%hash) = @_;
	# option de Data::Dumper
	$Data::Dumper::Indent			= 1;
	$Data::Dumper::Quotekeys	= 0;
	$Data::Dumper::Sortkeys		= 1;
	$Data::Dumper::Useqq			= 1;  
	
	my $dumper = Dumper(\%hash);
	
	return($dumper);
}

# writeLog(string, string)
# Ecriture du fichier log - dump des hashs
# global var : %Hsched %Hjobs %Hcluster $cDate
# return	(void) 
sub writeLog {
	my ($file_log, $service) = @_;
	my $key ;
	my $dump_hash;
	
	open my $fh_log, '>:encoding(utf-8)', $file_log or die $!;
	
	print {$fh_log} $service . " (" . $ENV{"USERNAME"} . ")\n" . $cDate . "\n";
	
	$dump_hash = dumperHash(%Hsched);
	$dump_hash =~ s/\"\,\n\s*\"/\"\, \"/g;
	$dump_hash =~ s/\[\n\s*/\[ /g;
	$dump_hash =~ s/\n\s*\]/ \]/g;
	print {$fh_log} "\n\%Hsched\n$dump_hash\n";
	$dump_hash = dumperHash(%Hjobs);
	print {$fh_log} "\n\%Hjobs\n$dump_hash\n";
	$dump_hash = dumperHash(%Hcluster);
	print {$fh_log} "\n\%Hcluster\n$dump_hash\n";
	$dump_hash = dumperHash(%Hlink);
	print {$fh_log} "\n\%Hlink\n$dump_hash\n";
	$dump_hash = dumperHash(%Hconvfreq);
	print {$fh_log} "\n\%Hconvfreq\n$dump_hash\n";
	$dump_hash = dumperHash(%Opt);
	print {$fh_log} "\n\%Opt\n$dump_hash\n";
	
	close $fh_log or die $!;
}

# makeXlsFile(string, string)
# Ecriture du fichier xls
# global var : %Hsched %Hjobs $br
# return	(void) 
sub makeXlsFile {
	my ($file, $worksheet) = @_;
	no warnings 'uninitialized';
	my $workbook;
	my $i 	= 0;
	my $col = 0;
	# Tableau qui contient la largeur des colonne de worksheet1
	my @width;
	my $width_min = 10;
	my $width_max = 50;

	# Chk si creation fichier OK ?
	open(STDERR,'>/dev/null') or die $! ;
	eval {
		$workbook = Spreadsheet::WriteExcel->new($file) or die $!;
	};
	close(STDERR) or die $! ;
	if ($@) {	return("KO !\n\t$@"); }
	
	my $worksheet1 = $workbook->add_worksheet($worksheet);
	my $worksheet2 = $workbook->add_worksheet('JOBs');
	
	# Colonne de $worksheet1 => Jobstream Definition
	my @title = ("JS Name", 
							"DESCRIPTION", "ON", "EXCEPT", "AT", "EVERY", "FOLLOWS", "JFOLLOWS", "NEEDS",
							"OPENS", "CARRYFORWARD", "OUTFILE", "VFOLLOWS", "NEXT", "CLUSTER", "JOB_INC");
	
	# Definition des formats
	my $format_title = $workbook->add_format(	
		center_across =>	1,
		bold 					=>	1,
		size					=>	12,
		border 				=>	5,
		color 				=>	'black',
		bg_color 			=>	'cyan',
		align 				=>	'vcenter');
	my $format_key 	= $workbook->add_format(	
		bold 					=>	1,
		bg_color 			=>	'yellow',
		align 				=>	'vcenter');
	my $format_valueMain = $workbook->add_format(	
		size				 	=>	8,
		bg_color			=>	0x1B,
		border 				=>	1,
		align 				=>	'vcenter');
	my $format_valueConf = $workbook->add_format(
		size					=>	8,
		border 				=>	4);
	my $format_defJob = $workbook->add_format(
		size					=>	8,
		border 				=>	4);
	
	# Ecriture des titres de $worksheet1
	foreach (@title) { 
		$worksheet1->write(0, $col, $_, $format_title);  
		$width[$col] = $width_min;
		$col++;
	}
	
	# Ecriture du contenu de $worksheet1
	foreach my $key (sort keys %Hsched) {
		# Next si Jobstream ne provient pas du fichier source
		next if ( $Hsched{$key}{'FROM'} ne "main");
		
		$col = 0;
		++$i;
		
		foreach ( @title ) {
			my $value;
			my $ref = "undef";
			if ( $Hsched{$key}{$_} ) { $ref = \$Hsched{$key}{$_} }
			my $cformat = (	$_ eq "OUTFILE" ||
											$_ eq "VFOLLOWS" ||
											$_ eq "NEXT" ||
											$_ eq "CLUSTER"
										) ? $format_valueConf : $format_valueMain;
			
			if ( $col == 0 ) {
				$value = $key;
				$worksheet1->write_url($i, $col, "external:Jobstream/$key.txt", $value, $format_key);
			} else {
				if ( ref($$ref) eq "ARRAY" ) {
					$value = join(";", @{$Hsched{$key}{$_}});
					if ( $_ eq "ON" ) { $value =~ s/$br/;/g; }
				} elsif ( ref($ref) eq "SCALAR" ) {
					$value = $Hsched{$key}{$_};
				}	
				$worksheet1->write($i, $col, $value, $cformat);
			}
			my $lenght = length($value);
			if ( $width[$col] < $lenght ) { $width[$col] = $lenght; }
			$col++;
		}
	}
	
	# Fitre automatique
	$worksheet1->autofilter(0, 0, $i, $#title);
	# figer les volets
	$worksheet1->freeze_panes(1, 1);
	
	$col = 0;
	foreach ( @width ) {
		if ( $_ > $width_max ) { $_ = $width_max; }
		# largeur de colonne
		$worksheet1->set_column($col, $col, $_);
		$col++;
	}
	
	# worksheet2 => jobs
	# Titre
	$worksheet2->write(0, 0, "CPU", $format_title);
	$worksheet2->write(0, 1, "Jobs", $format_title);
	$worksheet2->write(0, 2, "Definition", $format_title);
	
	# Contenu
	$i = 1 ;
	foreach my $key ( sort keys %Hjobs ) {
		my ($cpu, $job) = split ("#", $key);
		$worksheet2->write($i, 0, $cpu, $format_key);
		$worksheet2->write($i, 1, $job, $format_valueMain);
		my $def = $Hjobs{$key}{'DEF'};
		chomp($def);
		$def =~ s/^.*\n//;
		$format_defJob->set_text_wrap();
		$worksheet2->write($i, 2, $def, $format_defJob);
		$i++;
	}
	
	# largeur de colonne
	$worksheet2->set_column(0, 0, 10);
	$worksheet2->set_column(1, 1, 10);
	$worksheet2->set_column(2, 2, 80);
	# Fitre automatique
	$worksheet2->autofilter(0, 0, $i, 2);
	# figer les volets
	$worksheet2->freeze_panes(1, 1);

	return("Ok");
}

# _add_carac(ref(SCALAR), string)
# Ajoute des carac à la fin
# global var :
# return	(void) 
sub _add_carac {
	my $var = shift;
	my $add = shift;
	$$var = $$var . $add ;
}


1;
__END__