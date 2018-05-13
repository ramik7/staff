#!/pkg/perl/5.26.0/bin/perl

#Remove directories the Mesos agents local hard drives
#The submitter will delete his own data from all Mesos agent hosts
#
#This script is being called from SUID to root binary, /pkg/local/bin/mremove <directory>
#SRC: /pkg/local/src/mremove.c 
#
#Rami Krankurs
#For GM, ATCI
#November 2017

use strict;
use warnings;

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $maprefix="avhersrv";		#Mesos agent prefix hostname
my @mnum=("05", "06", "07", "12");	#Add more agent hosts here (better is to use an external hosts file)
#my $ruid;
my $key="/prj/local/etc/ssh/sync";
my $sync="/prj/local/scripts/doremove.pl";
my $sshf="-q -oStrictHostKeyChecking=no";
my $ruser="root";
my $directory="$ARGV[0]";
my $ruid="$ARGV[1]";

#print "AAA $directory $ruid\n";

foreach (@mnum){
	#system("ssh $sshf -i $key $ruser\@$maprefix$_ hostname");
	#print "system(ssh $sshf -i $key $ruser\@$maprefix$_ $sync $directory $ruid)\n";
	system("ssh $sshf -i $key $ruser\@$maprefix$_ $sync $directory $ruid");
}
