#
# Name: lib_log.pl
# 
# SVN Information:
# $Revision$
# $Date$
#
use POSIX qw(strftime);
# use DateTime;
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

# dumperHash(string, string)
# Ecriture du fichier log - dump des hashs
# global var : %Hsched %Hjobs %Hcluster $cDate
# return	(void) 
sub writeLog {
	my ($file_log) = @_;
	my $key ;
	my $dump_hash;
	
	open my $fh_log, '>:encoding(utf-8)', $file_log or die $!;
	
	print {$fh_log} $cDate  . "\n";
	
	$dump_hash = dumperHash(%Hsched);
	print {$fh_log} "\n\%Hsched\n$dump_hash\n";
	$dump_hash = dumperHash(%Hjobs);
	print {$fh_log} "\n\%Hjobs\n$dump_hash\n";
	$dump_hash = dumperHash(%Hcluster);
	print {$fh_log} "\n\%Hcluster\n$dump_hash\n";
	$dump_hash = dumperHash(%Hconvfreq);
	print {$fh_log} "\n\%Hconvfreq\n$dump_hash\n";
	
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
							"DESCRIPTION", "ON", "EXCEPT", "AT", "EVERY", "FOLLOWS", "NEEDS",
							"OPENS", "CF", "OUTFILE", "VFOLLOWS", "NEXT", "CLUSTER", "aJOBS");
	
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
		next if ( $Hsched{$key}{'FROM'} ne "Main");
		
		$col = 0;
		++$i;
		
		foreach ( @title ) {
			my $value;
			my $ref = \$Hsched{$key}{$_};	
			my $cformat = (	$_ eq "OUTFILE" ||
											$_ eq "VFOLLOWS" ||
											$_ eq "NEXT" ||
											$_ eq  "CLUSTER"
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