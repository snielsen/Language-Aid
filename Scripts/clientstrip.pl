#!/usr/bin/env perl
# Copyright 2006-2011 Aoren LLC. All rights reserved.

use File::Basename;

open(INFILE, @ARGV[0]) or die "Can't open @ARGV[0]: $!";

my @lines = <INFILE>;

my $bigthing = "";

foreach(@lines)
{
	$bigthing .= $_;
}

close INFILE;

$bigthing =~ s/\t*#ifdef\s+LAINTERNAL((.|\s)*?)\t*#else/\n#else/g;
$bigthing =~ s/\s?\t*#else((.|\s)*?)\t*#endif\s?/$1/g;
$bigthing =~ s/\s?\t*#ifdef\s+LAINTERNAL((.|\s)*?)\t*#endif\s?//g;
$bigthing =~ s/\s?\t*#endif//g;

open(OUTFILE, ">/Library/Application Support/Language Aid/" . basename(@ARGV[0]) );

print OUTFILE $bigthing;

close OUTFILE;