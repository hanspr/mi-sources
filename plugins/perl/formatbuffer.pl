#!/usr/bin/perl

use Fcntl ':mode';

our ($fn,$line,$n,$permissions);
our ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks,$spc);

binmode STDOUT,':utf8';
use utf8;

$fn = $ARGV[0];
$spc = $ARGV[1];
if ($spc) {
	$spc = ' 'x$ARGV[2];
}

if ((!$fn)||(!-e $fn)) {
	exit 0;
}

$n = 0;
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = lstat($fn);
$permissions = sprintf "%04o", S_IMODE($mode);
open(FO,"<:utf8",$fn);
open(FN,">:utf8","$fn.new");
while($line = <FO>) {
	$line =~ s/^[\t ]+//;
	if ($n) {
		my $tabs;
		if ($spc) {
			$tabs = $spc x $n;
		} else {
			$tabs = "\t" x $n;
		}
		$line = $tabs.$line;
	}
	if ($line =~ /^\t+#/) {
		print FN $line;
		next;
	}
	my ($b,$match) = balanced($line);
	if ($b>0) {
		$n++;
	} elsif ($b<0) {
		$n--;
		if ($spc) {
			$line =~ s/^$spc//;
		} else {
			$line =~ s/^\t//;
		}
	} elsif (($match)&&($n>0)) {
		if ($spc) {
			$line =~ s/^$spc//;
		} else {
			$line =~ s/^\t//;
		}
	}
	#	print "n=$n  ",$line;
	print FN $line;
}
close FO;
close FN;

if ((-e "$fn.new")&&(-s "$fn.new" > 0)) {
	system "mv -f $fn $fn.old";
	system "mv -f $fn.new $fn";
	system "chmod $permissions $fn";
	unlink "$fn.old";
}

sub balanced {
	my $str = shift;
	my $b = 0;
	my $match=0;

	$str =~ s/\".*?\"//;
	$str =~ s/\''.*?\'//;

	my $open = () = $str =~ /[\{\[\(]/g;
	my $close = () = $str =~ /[\}\]\)]/g;

	if (($open + $close > 0)&&($str =~ /^(?:(?![\{\[\(]).)*?([\}\]\)].+?[\{\[\(])/)) {
		$match = 1;
	}
	$b = $open - $close;
	return ($b,$match);
}
