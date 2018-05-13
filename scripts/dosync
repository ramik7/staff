#!/pkg/perl/5.26.0/bin/perl

#Replication for Mesos
#The submitter will specify the source data directory and the drive destination.
#destination drives, ffd (full flash drive), hdd (SATA hard drive).
#
#This script is being called from SUID to root binary, /pkg/local/bin/dosync
#SRC: /pkg/local/src/dosync3.c 
#
#Rami Krankurs
#For GM, ATCI
#October 2017

use strict;
use warnings;
use Getopt::Long;

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $msync="/pkg/local/bin/msync";
my $maprefix="avhersrv";
my @mnum=("05", "06", "07", "12");	#Add more agent hosts here (better is to use an external hosts file)
my $input;
my $drive;
my $ruid;
my $key="/prj/local/etc/ssh/sync";
my $sync="/prj/local/scripts/syncme.pl";
my $sshf="-q -oStrictHostKeyChecking=no";
my $ruser="root";

GetOptions(
	'--drive=s' => \$drive,
        '--src=s' => \$input,
        '--ruid=s' => \$ruid)
or die(&print_usage);

sub print_usage{
	my $msusage="$0 --src <path_to_folder> --drive <hdd/ffd>";
	print "Usage:\n$msusage\n";
	print "\nhdd => SATA\n";
	print "ffd => Flash\n";
	print "@_\n";
	exit;
}

if((! defined $input)||(! defined $drive)){
        &print_usage;
}

if ( ! -e "$input" ){
	die "cannot access $input, please check the path validity\n";
}

if ( "$drive" !~ m/\bhdd\b|\bffd\b/ ){
	die "please specify the destination drive type <fdd/hdd> $drive\n";
}

foreach (@mnum){
	#system("ssh $sshf -i $key $ruser\@$maprefix$_ hostname");
	system("ssh $sshf -i $key $ruser\@$maprefix$_ $sync $input $drive $ruid");
}
