#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/unix_srv/local/scripts/uge";

#report scratch for Erez
#MISL slot assignment for each host

use Env::Path;
use strict;
use warnings;
use lib '/unix_srv/local/perl/modules';
use set817;
Env::Path->PATH->Prepend("$ENV{SGE_PATH}");

my $th;
my $grp="";
my $mem_total;
my $core="";
my $sf="";
my $slots="";
my @q="";

my @heavy = `qconf -sq heavy`;
my @bulk = `qconf -sq bulk`;
my @host = `qhost | grep lnx | grep -v arm  | grep -v mt | cut -d' ' -f 1`;
my @GRP = `qconf -shgrpl | grep -v allhosts | grep -v yok`;

foreach(@host){
	chomp;
	$th="$_";
	&chks($th);
	&chkgrp($th);
	foreach('@heavy', '@bulk'){
		@q="$_";
		&chkslots(@q);
	}
	#&chkslots($grp);
	print "$th $mem_total $core $slots\n";
}

sub chkgrp{
	foreach(@GRP){
		chomp;
		$grp="$_";
		$grp =~ s/@//;
		next if /! $grp/;
		my @GRPL = `qconf -shgrp_tree \@$grp`;
		my @qfound = grep(/$th/, @GRPL);  
		my $asz=scalar(@qfound);
		if ("$asz" != "0"){
			$grp="\@$grp";
			last;
		}
	}
}
sub chkslots{
	#foreach(@heavy){
	print "QQQ @q\n";
	foreach(@q){
		chomp;
		if(/slots/){$sf="y";}
		if((/$grp/)&&("$sf" eq "y")){
			my @TMP = split "$grp=", $_;
			$slots="$TMP[1]";
			$slots =~ s/]//;
			$slots =~ s/,//;
			if("$slots" =~ "@"){
				my @TMP2 = split '@', $slots;
				$slots="$TMP2[0]";
				$slots =~ s/\[//;
			}
			$slots =~ s/\s+\\//;
			last;
		}
	}
	$sf="";
}
sub chks{
	use POSIX;
	my $lookup="m_mem_total m_core";
	my @GDATA=`qhost -h $th -F $lookup`;
	foreach(@GDATA){
		chomp;
		if(/m_mem_total/){
			my @TMP = split '=', $_;
			$TMP[1] =~ s/G//;
			$mem_total=ceil($TMP[1]);
		}
		if(/m_core/){
			my @TMP = split '=', $_;
			$core=ceil($TMP[1]);
		}
	}
}
