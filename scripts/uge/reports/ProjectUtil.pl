#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/unix_srv/local/scripts/uge";

#Oneflow project usage report
#Will pickup project line from MARSHELL_COMMAND
#Then will print its memory and slots utilization

#Rami Krankurs
#Marvell, May 2018

use Env::Path;
use strict;
use lib '/unix_srv/local/perl/modules';
use set854;
Env::Path->PATH->Prepend("$ENV{SGE_PATH}");

use List::MoreUtils qw(uniq);
use POSIX;

#=========================
my $marshell="LM_PROJECT";
my $mark="env_list";
#=========================

my $job;
my $project;
my $cpu;
my $rmem;
my $pmem;
my @ajobs;
my $uzer;
my @projects;
my @all;
my @qstat = `qstat -u '*'`;
foreach(@qstat){
	chomp;
	my @tmp = split '\s+', $_;
	$job="$tmp[1]";
	if("$job" =~ /\d+/){
		push(@ajobs, "$job");
		my @tmp=`qstat -j $job`;
        	foreach(@tmp){
                	chomp;
			if(/$mark/){
                        	my @tmp = split ',', $_;
                        	foreach(@tmp){
                                	if(/$marshell/i){
                                        	my @tmp2 = split '=', $_;
                                        	my $proj="$tmp2[1]";
                                        	push(@projects, "$proj");
                                	}
                        	}
                	}
		}
	}
}

my @rprojects = uniq @projects;
foreach(@ajobs){
	$job=$_;
	&getprjinfo($job);
	push(@all, "$job:$project:$rmem:$pmem:$cpu");	#JOB:PROJECT:MEM_REQ:MEM_IN_USE:CPU
}
&psort;

sub getprjinfo{
	my @tmp=`qstat -j $job`;
	foreach(@tmp){
		chomp;
		if(/^owner/){
			my @tmp = split ':', $_;
			$uzer="$tmp[1]";
			$uzer =~ s/\s+//g;
		}			
		if(/^group/){
			my @tmp = split ':', $_;
			my $grp="$tmp[1]";
			$grp =~ s/\s+//g;
		}			
		if(/^granted_req/){
			my @tmp = split ':', $_;
			my @tmp1 = split ',', $tmp[1];
			my @req=@tmp1;
			my @mem = grep ( /physical_memory/, @req );
			my @cpu = grep ( /physical_cpu/, @req );
			$rmem = join "", @mem;
			$cpu = join "", @cpu;
			$rmem =~ s/physical_memory=//;
			$cpu =~ s/physical_cpu=//;
			$rmem =~ s/\s+//;
			#----------------
			$rmem =~ s/$/G/; #=> REQ MEM
			$cpu =~ s/\s+//; #=> REQ CORE
		}
		if(/^usage/){
			my @tmp = split ',', $_;
			my @pmem = split ',', $tmp[11];
			$pmem = join "", @pmem;
			$pmem =~ s/pmem=//;
			$pmem =~ s/\s+//;
			my $suff=$pmem;
			$suff =~ s/\d+.\d+//;
			$pmem =~ s/$//;
			$pmem=ceil($pmem);
			#----------------
			$pmem="$pmem$suff"; #=> MEM USAGE
		}
		if(/$mark/){
			my @tmp = split ',', $_;
			foreach(@tmp){
				if(/$marshell/i){
					my @tmp2 = split '=', $_;
					$project="$tmp2[1]";
				}
			}
		}
	}
}

sub psort{
	foreach (@rprojects){
		my $tprj="$_";
		my @a = grep ( /test/, @all );
		print "@a\n";
	}
}
