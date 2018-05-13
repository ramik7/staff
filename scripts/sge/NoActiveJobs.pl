#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

#OneFlow(DC3), UGE854
#show hosts without active running jobs.

#Rami Krankurs
#February 2018, Marvell

use Env::Path;
use strict;
use warnings;
#
my $ENV;
$ENV->{SGE_ROOT} = "/proj/sge/uge854";
$ENV->{SGE_CELL} = "REDA";
$ENV->{SGE_CLUSTER_NAME} = "DC3_UREDA";
$ENV->{SGE_QMASTER_PORT} = "6444";
$ENV->{SGE_EXECD_PORT} = "6445";
$ENV->{SGE_PATH} = "/proj/sge/uge854/bin/lx-amd64";

$ENV{SGE_ROOT}="$ENV->{SGE_ROOT}";
$ENV{SGE_CELL}="$ENV->{SGE_CELL}";
$ENV{SGE_CLUSTER_NAME}="$ENV->{SGE_CLUSTER_NAME}";
$ENV{SGE_QMASTER_PORT}="$ENV->{SGE_QMASTER_PORT}";
$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";

Env::Path->PATH->Append("$ENV->{SGE_PATH}");
my @ah;
my @tah;
my $rf;

open ("ahosts", "qhost|");
while(<ahosts>){
	chomp;
	if(/amd64/){
		@tah = split '\s+', $_;
		next if ("$tah[6]" eq "-");
		push(@ah, "$tah[0]");
	}
}
close "ahosts";

foreach (@ah){
	$rf="";
	my $thost="$_";
	open ("jl","qhost -j -h $_|");
		while(<jl>){
		chomp;
		if(/\s+r\s+/){$rf="r";}
	}
	if("M$rf" eq "M"){print "$thost\n";}
	close "jl";
}
