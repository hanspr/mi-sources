#!/usr/bin/perl

use utf8;
binmode STDOUT, 'utf8';

our $FILE = $ARGV[0];

if (!$FILE || !-e $FILE || -d $FILE) {
    exit 1;
}
our $DEBUG = 0;
our @STACK = ();

IndentCode();

exit 0;

sub IndentCode {
    my ($indent, $lc, @quoted_parts, $ci);
    my $I  = 0;
    my $ch = " ";
    my $sp = 4;

    open(F, "<:utf8", $FILE)       or exit 1;
    open(O, ">:utf8", "$FILE.tmp") or exit 1;
    while (my $l = <F>) {
        if ($DEBUG) {
            print "$l";
        }
        $l =~ s/ +$//;
        $lc = $l;
        $lc =~ s/\n|\r//g;
        if (!$lc) {
            print O $l;
            next;
        }
        # Set indentetion
        $ci = $I;
#        if ($lc =~ /<\/(?:table|tr|div)/) {
#            $ci--;
        if ($lc =~ /<(?:table|tr|div|head|style|xsl:(?:if|choose|when|for-each|otherwise|template))/ && $lc !~ /<\/(?:table|tr|div|head|style|xsl:(?:if|choose|when|for-each|otherwise|template))/) {
            # Indent
            push @STACK, 1;
        } elsif ($lc =~ /<\/(?:table|tr|div|head|style|xsl:(?:if|choose|when|for-each|otherwise|template))/ && $lc !~ /<(?:table|tr|div|head|style|xsl:(?:if|choose|when|for-each|otherwise|template))/) {
            # Outdent
            pop @STACK;
            $ci--;
        }
        $I = scalar(@STACK);
        if ($DEBUG) {
            print "$I , $ci\n";
        }
        $indent = $ch x ($sp * $ci);
        if ($DEBUG) {
            print "indent = '$indent'\n";
        }
        $lc =~ /^(\s+)/;
        if ($DEBUG) {
            print "current intent = '$1'\n";
            print length($indent), "!=", length($1), "\n";
        }
        if (length($indent) != length($1)) {
            if ($DEBUG) {
                print "apply indentation\n";
            }
            $l =~ s/^\s*/$indent/;
        }
        # Print formated line
        print O $l;
        if ($DEBUG) {
            print "$l";
            my $x = <STDIN>;
        }
    }
    close O;
    close F;
    if (!$DEBUG) {
        system "mv -f $FILE.tmp $FILE";
    }
}
