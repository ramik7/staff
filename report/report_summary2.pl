#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

#Rami Krankurs
#February 2018

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

use strict;
use Capture::Tiny 'capture_merged';

#R#my $summary="/unix_srv/pkg/local/summary";
my $data="/unix_srv/pkg/local/ugdata";	#source data to analyze.
my @darray;
my @rmq = ("heavy", "bulk");
my @mq;
my @mq = @rmq;
my %key;
my @mkfile;
my $lnkn="k";
my $lnumber;
my %range = (
    "A" => "0",
    "B" => "1",
    "C" => "2",
    "D" => "3",
    "E" => "4",
    "F" => "5",
);

#====================================================================================================
#We'll create an array (@darray) that will hold all directory names that will later will be accessed for its file analysis.
#====================================================================================================
open(datadir, "ls $data|");
while (<datadir>){
	chomp;
	if (-d "$data/$_"){
		my $da_obj;
                my @da = split '-', $_;
                $da_obj->{day} = $da[0];
                $da_obj->{month} = $da[1];
                $da_obj->{year} = $da[2];
		push(@darray, $da_obj);
	}
}
close datadir;
#====================================================================================================
#directory names that @darray has within from the following format: DD/MM/YYYY
#sorting @darray by date, the result is @darray containing its elements sorted by its date numbering.
#====================================================================================================
#$DB::single = 1;

sub cmp {
	my ($a,$b) = @_;
	$a->{month} <=> $b->{month} || $a->{day} <=> $b->{day} || $a->{year} <=> $b->{year};
}

@darray = sort { &cmp($a,$b) } @darray;

foreach (@darray){
        $_ = $_->{day}."-".$_->{month}."-".$_->{year};
	my $qdir="$_";
	foreach (@mq){
		my $filename="$data/$qdir/$_\_data";
		print "\n$filename\n";
		print "="x50,"\n";
		open(mrfile,"$filename");
		$lnumber="1";
		while(<mrfile>){
			chomp;
			my @mft = split(/:/, $_);
			foreach my $letter (sort keys %range){
				$key{"$lnkn$lnumber$letter"} = "$mft[$range{$letter}]";
			}
			foreach my $letter (sort keys %range){
				print "$lnkn$lnumber$letter => $mft[$range{$letter}] ";
				my $tmpkey="$lnkn$lnumber$letter";
				#R#print "$tmpkey\n";
				#my %\$tmpkey;
				#my %k1069F;
				#$lkey{"$lnkn$letter"} = "
			}
			print "\n";
			$lnumber++;
		}
	}
	@mq=@rmq;
	#open (qrdir, "$data/
	#print "$_\n";
}
