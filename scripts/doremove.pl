#!/pkg/perl/5.26.0/bin/perl

#Rami Krankurs
#For GM, ATCI, November 2017

use strict;
use warnings;
use Sys::Hostname;
use Term::ANSIColor;

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $ruid="$ARGV[1]";
my $uname  = getpwuid($ruid);
my $directory="$ARGV[0]";
my $destdirtype;
my $stagedir="/local/mnt/data/$uname";
my $host=hostname;
my $me=getpwuid ("$ruid");
my @uzer = split(/\s+/, $me);
my $stagepath="/local/mnt/data/@uzer";
my $realdatapath;

if ( -l "$stagepath/$directory" ){
	$realdatapath=readlink "$stagepath/$directory";
	&doremovedata;
}

sub doremovedata{

	print "$host: Removing $directory from $realdatapath "; print color("green"), "START\n", color("reset"); 
	system("rm -rf $realdatapath");
	system("rm -f $stagepath/$directory");
	print "$host: Removing $directory from $realdatapath "; print color("green"), "DONE\n\n", color("reset"); 
	print "+"x125,"\n";
}
