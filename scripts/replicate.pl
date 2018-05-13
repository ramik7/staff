#!/pkg/perl/5.26.0/bin/perl

#QNAP mirror for AV, GM Hertzliya
#Rami Krankurs
#October 2017

use strict;
use warnings;
use Getopt::Long;

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $msync="/pkg/local/bin/msync";
my $maprefix="avhersrv";
my @mnum=("05", "06", "07", "12");
my $input;
my $key="/prj/local/etc/ssh/sync";

GetOptions(
        '--src=s' => \$input)
or die(&print_usage);

sub print_usage{
        my $msusage="$0 --src <path_to_folder>";
        print "Usage:\n$msusage\n";
        print "@_\n";
        exit;
}

foreach (@mnum){
	print "$_\n";
}
