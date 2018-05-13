#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

use Env::Path;
use strict;
use warnings;
use Getopt::Long;
use List::MoreUtils qw(uniq);

my $ENV;
my $sghost;
my $tq;
my @ah;
my @sql;
#my @comp=("m_mem_total", "m_mem_free", "m_mem_used", "m_core", "cpu");

$ENV->{SGE_ROOT} = "/proj/sge/uge854";
$ENV->{SGE_CELL} = "REDA";
$ENV->{SGE_CLUSTER_NAME} = "DC3_REDA";
$ENV->{SGE_PATH} = "/proj/sge/uge854/bin/lx-amd64";
$ENV->{SGE_QMASTER_PORT} = "6444";
$ENV->{SGE_EXECD_PORT} = "6445";
#=================================================
$ENV{SGE_ROOT}="$ENV->{SGE_ROOT}";
$ENV{SGE_CELL}="$ENV->{SGE_CELL}";
$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";
$ENV{SGE_PATH}="$ENV->{SGE_PATH}";
$ENV{SGE_QMASTER_PORT}="$ENV->{SGE_QMASTER_PORT}";
$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";
#=================================================
Env::Path->PATH->Prepend("$ENV->{SGE_PATH}");
&gqueue;
#foreach(@sql){
#	print "$_\n";
#}
#exit;

&gethostlist;
&process;
#
sub gethostlist{
	open("ahosts", "qhost|");
	while(<ahosts>){
		chomp;
		next if (/-$/);
		if(/amd64/){
			my @tah = split '\s+', $_;
			push(@ah, "$tah[0]");
		}
	}
	close "ahosts";
}

sub process{
	foreach(@ah){
		my $thishost="$_";
		$sghost->{hostname}="$thishost";
		print "$sghost->{hostname}\n";
		#$sghost->{queue}="$tq";
		#print "$thishost\n";
		#print "="x50,"\n";
		open("mqhost", "qhost -F -q -h $_|");
		while(<mqhost>){
			chomp;
			my $ent="$_";
			if(((((/m_mem_total=/)||(/m_mem_free=/)||(/m_mem_used=/)||(/m_core=/)||(/cpu=/))))){
				$ent =~ s/hl://;
				$ent =~ s/\.\d+/\.\d{2}/;
				#s/\G([^\/.]*)\./\1\//g
				print "$ent\n";
			}
			foreach(@sql){
				if(/\w+$_\w+/){
					#print "$sghost->{hostname} $_\n";
				}
			}
		}
	}
}

sub gqueue{
	open("sql","qconf -sql|");
	while(<sql>){
		chomp;
		next if (/all.q/);
		push(@sql, "$_");
	}
}		
