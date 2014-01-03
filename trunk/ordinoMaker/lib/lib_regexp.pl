#
# Name: lib_regexp.pl
# 
# SVN Information:
# $Revision$
# $Date$
#

# RegExpMain(string)RegExpFreq(string) RegExpOnExcept(string)
## RegExpNeeds(string) RegExpFollows(string)
#### RegExpOpens(string) RegExpAt(string) RegExpDesc(string)
# applique les regexp en fonction du type d'info
# global var : %Hconvfreq
# return	(string) 

sub RegExpMain {
	my ($line) = @_ ;	
	$line =~ s/\n//g;
	$line =~ s/\s+/ /g;
	$line =~ s/^\s+|\s+$//g;
	return "$line";
}

sub RegExpFreq {
	my ($return) = @_ ;
	
	for my $key ( keys %Hconvfreq ) {	$return =~ s/$key/$Hconvfreq{$key}/	}	

	return ("$return");
}

sub RegExpOnExcept {
	my ($line) = @_ ;
	# print "\tRegExpOn " . $line;
	$line = RegExpFreq("$line");
	$line =~ s/$_//g foreach ('^ON\b','^EXCEPT\b','RUNCYCLE','RULE[1-9]','CALENDAR[0-9]','FREQ=', '\"', ';$');
	
	$line = RegExpMain("$line");
	return "$line";
}

# gobal var :cpuName
sub RegExpNeeds {
	my ($line) = @_ ;
	# print "\tRegExpNeeds " . $line ;
	$line =~ s/$_// foreach ('NEEDS\b',"$cpuName#");

	$line = RegExpMain("$line");
	return "$line";
}

sub RegExpFollows {
	my ($line,$cpu) = @_ ;
	# print "\tRegExpFollows " . $line . "|" . $cpu . "\n";
	$line =~ s/^FOLLOWS\b//;
	$line =~ s/.@//;
	$line =~ s/\.[0-9,a-z,A-Z]+$//;
	$line = RegExpMain("$line");
	$line = uc($line);

	my @splitfollows = split('#', $line);
 	if ( $cpu eq $splitfollows[0] ) { $line = $splitfollows[1] ; }
 	
	return "$line";
}

sub RegExpOpens {
	my ($line) = @_ ;
	# print "\tRegExpOpens " . $line ;
	$line =~ s/$_// foreach ('^OPENS?\b','"$');
	$line = (split(/[\\\/]/, $line))[-1];
	$line =~ s/\?+$//;
	$line = RegExpMain("$line");
	return "$line";
}

sub RegExpAt {
	my ($line) = @_ ;
	# print "\tRegExpAt " . $line ;
	$line =~ s/AT /@/;
	$line =~ s/ONUNTIL //;
	$line =~ s/UNTIL /-/;
	$line =~ s/ -/-/;
	$line = RegExpMain("$line");
	return "$line";
}

sub RegExpDesc {
	my ($line) = @_ ;
	# print "\tRegExpDesc " . $line ;
	$line =~ s/$_//g foreach ('^DESCRIPTION\b', '"');
	$line = RegExpMain(RegExpDelNoAlph($line));
	return($line);
}

# RegExpDelNoAlph(string)
# Supprime les carc. non alpha-num qui ne sont pas pris en charge
# global var : 
# return	(string) 
sub RegExpDelNoAlph {
	my ($return) = @_ ;
	$return =~ s/$_//g foreach ('&' ,'{' ,'}' ,'\|');
	return ("$return");
}

# splitLine(string)
# split /:=/ d'une chaine en 3
# global var : 
# return	(string, string, string) 
sub splitLine {
	my ($line) = @_;
	$line = RegExpDelNoAlph("$line");
	my @custom = split('[:=]', $line, 3);
	my $ref = uc(RegExpMain($custom[0]));
	my $key = uc(RegExpMain($custom[1]));
	my $value = RegExpMain($custom[2]);
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

1;