#!/pkg/perl/5.26.0/bin/perl

#Rami Krankurs
#For GM, ATCI, November 2017

use strict;
use warnings;
use Sys::Hostname;
use Term::ANSIColor;

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $msync="/pkg/local/bin/msync";
my $ruid="$ARGV[2]";
my $uname  = getpwuid($ruid);
my $dstdrive="$ARGV[1]";
my $srcdata="$ARGV[0]";
my $destdirtype;
my $stagedir="/local/mnt/data/$uname";
my $rsync="rsync -az";
my $host=hostname;

my @srcdata = split(/\//, $srcdata);
my $srcdatadir = pop @srcdata;

if("$dstdrive" eq "hdd"){
	$destdirtype="disk/01";
}
else{
	$destdirtype="flash";
}
my $destdatadir="/local/$destdirtype/data/$uname";
my $gname="linux_users";

#my $me = getpwuid($<);
#print "TOTAL $ARGV[0] $ARGV[1] $ARGV[2] $uname\n";

if (! -d "$destdatadir"){
	system("mkdir -p $destdatadir");
	system("chown $uname $destdatadir");
	system("chgrp $gname $destdatadir");
}
if (! -d "$stagedir"){
	system("mkdir -p $stagedir");
	system("chown $uname $stagedir");
	system("chgrp $gname $stagedir");
}
print "$host: Replicating $srcdata => $destdatadir/$srcdatadir -"; print color("green"), "START\n", color("reset"); 
system("$rsync $srcdata/ $destdatadir/$srcdatadir");
symlink("$destdatadir/$srcdatadir", "$stagedir/$srcdatadir");
print "$host: Replicating $srcdata => $destdatadir/$srcdatadir -"; print color("green"), "DONE\n\n", color("reset"); 
print "Your data will be available from: $stagedir/$srcdatadir\n";
print "+"x125,"\n";
