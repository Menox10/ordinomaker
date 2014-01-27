#
# Name: lib_regexp.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

use Switch;

# regexpSwitcher($keyword, $line)
# regexp - Switcher en fc du keyword
# global var : 
# return($string)
sub regexpSwitcher {
	my ($keyword, $line) = @_;

	switch ($keyword) {
		case /^FOLLOWS$/							{ $line =~ s/(.+)\..*$/$1/			 }
		case /^CARRYFORWARD$/					{	$line = "y"										 }
		case /^DESCRIPTION$/					{ $line = re_del_noAlpha($line) }
		case /^ON$|^EXCEPT$/					{	$line = re_freq($line)				 }
		case /^OPENS?$/								{	$line = re_opens($line)				 }
		case /^AT$|^UNTIL$|^ONUNTIL$/	{ $line = re_at($line)					 }
	}

	if ( $keyword ) { $line =~ s/$keyword\s// }
	$line =~ s/$cpuName#//;
	trim(\$line);

	return("$line");
}

sub RegExpMain {
	my ($line) = @_ ;	
	$line =~ s/\n//g;
	$line =~ s/\s+/ /g;
	$line =~ s/^\s+|\s+$//g;
	return "$line";
} 
sub re_freq {
	my ($line) = @_;
	$line =~ s/$_//g foreach ('RUNCYCLE','RULE[1-9]?','CALENDAR[0-9]?', 'SIMPLE[0-9]?');
	for my $key ( keys %Hconvfreq ) {	$line =~ s/$key/$Hconvfreq{$key}/	}
	$line =~ s/\s.*\sDESCRIPTION\s\".*\"\s/ /;
	$line =~ s/\"//g;
	$line =~ s/;$//g;
	return("$line");
}
sub re_opens {
	my ($line) = @_ ;
	$line =~ s/$_//g foreach ( '"', '\?{6,20}' );
	my ($path, $spec) = split (/\s\(/, $line);
	my $return;
	
	# path
	$path = (split(/[\\\/]/, $path))[-1];
	trim(\$path);
	
	# spec
	if ( $spec ) {
		$spec =~ s/\)//g;
		$spec =~ s/\-f \%p//g;
		trim(\$spec);
	}
	
	# return
	if ( ! $spec || $spec eq "" ) { 
		$return = "|$path|";
	} else {
		$return = "|$path|($spec)|";
	}
	
	return($return);
}
sub re_at {
	my ($line) = @_ ;
	$line =~ s/AT /@/;
	$line =~ s/UNTIL /-/;
	$line =~ s/ONUNTIL //;
	$line =~ s/ -/-/;
	$line =~ s/^\-/\@0600\-/;
	return "$line";
}
sub re_del_noAlpha {
	my ($return) = @_ ;
	$return =~ s/$_//g foreach ('&' ,'{' ,'}' ,'\|', '"');
	return ("$return");
}

# splitLine(string)
# split /:=/ d'une chaine en 3
# global var : 
# return	(string, string, string) 
sub splitLine {
	my ($line) = @_;
	
	$line = re_del_noAlpha("$line");
	my ($ref, $key, $value) = split('[:=]', $line, 3);
	$ref		= uc(RegExpMain($ref));
	$key 		= uc(RegExpMain($key));
	$value	= RegExpMain($value);
	
	return ("$ref","$key","$value");
}

# addBrLine(string, string, int)
# ajout de $c tout les x carc (ne coupe pas les mots)
# return	(string) 
sub addBrLine {
	my ($line, $c, $maxLine) = @_;
	my $i = 0;
	my $return = "";
	my $first = "Y";
	my @a = split( / /, RegExpMain("$line"));

	foreach my $mot ( @a ) {
		if ( length($mot) > $maxLine ) {
		$return .= $c  . $mot . $c ;
		$i = 0;
		$first = "Y";
		next;
		}
		
		$i += length($mot);
		
		if ( $i < $maxLine ) {
			if ( $first eq "Y" ) {
				$return .= $mot ;
				$first = "N" ;
			} else {
				$return .= " " . $mot ;
				++$i;
			}
		} else {
			$return .= $c . $mot;
			$i = length($mot) ;
		}
	}

	$return =~ s/^$c|$c$//;
	return ($return);
}

# trim(\$string)
# Supprime les espaces en début et fin de ligne
# global var : 
# return	(void)
sub trim {
	my $string = shift;
	 $$string =~ s/^\s+|\s+$//g;
}


1;