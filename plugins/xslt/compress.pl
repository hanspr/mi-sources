#!/usr/bin/perl

our ($fn, $line);

$fn = $ARGV[0];

if ((!$fn) || (!-e $fn)) {
    exit 0;
}

open(FO, "<:utf8", $fn);
open(FN, ">:utf8", "$fn.new");
while ($line = <FO>) {
    $line =~ s/^[ \t]+//;
    #    $line =~ s/^[\n\r]+$//g;
    if ($line) {
        print FN $line;
    }
}
close FN;
close FO;
if ((-e "$fn.new") && (-s "$fn.new" > 0)) {
    system "mv -f $fn.new $fn";
}
