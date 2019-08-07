#!/usr/bin/perl

our ($fn,$line);

$fn = $ARGV[0];

if ((!$fn)||(!-e $fn)) {
	exit 0;
}

open(FO,"<:utf8",$fn);
open(FN,">:utf8","$fn.new");
while($line = <FO>) {
	if ($line =~ /\{$/) {
		print FN $line;
		next;
	} elsif ($line =~ /^\t/) {
		print FN $line;
		next;
	} elsif ($line =~ /^\}/) {
		print FN $line;
		next;
	}
	$line =~ s/;/;\n\t/g;
	$line =~ s/\{/\{\n\t/;
	$line =~ s/\t+\}$/\}/;
	if ($line) {
		print FN $line;
	}
}
close FN;
close FO;
if ((-e "$fn.new")&&(-s "$fn.new" > 0)) {
	system "mv -f $fn.new $fn";
}
