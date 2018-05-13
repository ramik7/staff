#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

#OneFlow(DC3), UGE854
#show user active jobs

#Rami Krankurs
#March 2018, Marvell

use Env::Path;
use strict;
use warnings;
use Getopt::Long;
#
#================== Settings ====================
#Modify Only Here
#
my $ENV;
$ENV->{SGE_ROOT} = "/proj/sge/uge854";
$ENV->{SGE_CELL} = "REDA";
$ENV->{SGE_CLUSTER_NAME} = "DC3_UREDA";
$ENV->{SGE_QMASTER_PORT} = "6444";
$ENV->{SGE_EXECD_PORT} = "6445";
$ENV->{SGE_PATH} = "/proj/sge/uge854/bin/lx-amd64";
#=================================================

$ENV{SGE_ROOT}="$ENV->{SGE_ROOT}";
$ENV{SGE_CELL}="$ENV->{SGE_CELL}";
$ENV{SGE_CLUSTER_NAME}="$ENV->{SGE_CLUSTER_NAME}";
$ENV{SGE_QMASTER_PORT}="$ENV->{SGE_QMASTER_PORT}";
$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";

Env::Path->PATH->Append("$ENV->{SGE_PATH}");
my $me="$ENV{USER}";
my $status;
my @ah;
my @tah;
my $rf;
my $jf="";
my $sguser=$me;
my @jobs;
my $thost;
my @parsejob;
my $command="";
my $mem="";
my $cpu="";
my $wclock="";
my $qsub="";
my $req_mem;
my $jobID="";
my $toolname="";
my $cdir="";

GetOptions(
	'--user=s' => \$sguser)
or die(&print_usage);

if(("$me" eq "root")&&("$sguser" eq "root")){
	&print_root_usage;
}
if((! defined $sguser)||(! defined $me)){
        &print_usage;
}

#R#open ("ahosts", "qhost|");
#R#while(<ahosts>){
#R#	chomp;
#R#	if(/amd64/){
#R#		@tah = split '\s+', $_;
#R#		push(@ah, "$tah[0]");
#R#	}
#R#}
#R#close "ahosts";

&headline;
print "-"x145,"\n";
&main;
#R#foreach (@ah){
#R#	$rf="";
#R#	$thost="$_";
#R#	open ("jl","qhost -j -h $_|");
#R#		while(<jl>){
#R#		chomp;
#R#		print "MMMMMM $_\n";
#R#		if(/\s+\b$sguser\b\s+r\s+/){
#R#			$rf="r";
#R#			&qstat;
#R#			&getjinfo;
#R#		}
#R#	}
#R#	if("$rf" eq "r"){
#R#		$jf="on";
#R#		if("M$jobID" ne "M"){
#R#			printf ("%1s %13s %13s %12s %9s %21s %10s %12s %10s %15s",$jobs[1],$jobs[2],$toolname,$jobs[3],$jobs[4],$jobs[5],$wclock,$jobs[6],$cpu,"$mem/$req_mem");
#R#			if("M$command" eq "M"){$command="$qsub";}
#R#			print "\n";
#R#			printf ("%1s %10s","Working Dir:","[$cdir]");
#R#			print "\n";
#R#			printf ("%1s %10s","Command:","[$command]");
#R#			print "\n";
#R#			print "-"x145,"\n";
#R#		}
#R#	}
#R#	close "jl";
#R#	@jobs="";
#R#}
print "\n";
if("$jf" ne "on"){print "-No Active Jobs for $sguser.\n";}

#MARK1
sub main{
open ("mqstat","qstat -u '*'|");
	while(<mqstat>){
		chomp;
		my $dobj;
		my @dent = split '\s+', $_;
		$dobj->{jobid} = $dent[1];
		$dobj->{load} = $dent[2];
		$dobj->{cmd} = $dent[3];
		$dobj->{username} = $dent[4];
		$dobj->{status} = $dent[5];
		$dobj->{submitdate} = $dent[6];
		$dobj->{submittime} = $dent[7];
		$dobj->{qhostname} = $dent[8];
		my $qhs;
		my @qh = split "@", "$dobj->{qhostname}";
		my $qhs->{queuename} = $qh[1];
		my $qhs->{servername} = $qh[2];
		print "$dobj->{username} $dobj->{jobid} $dobj->{status} $dobj->{submitdate} $qhs->{queuename} $qhs->{servername}\n";
	}
close "mqstat";
}

sub print_usage{
	my $sgusageme="$0";
	my $sgusage="$0 --user <username>";
	print "Usage:\n$sgusageme [Yourself]\n== OR ==\n$sgusage --user <username> [Any other user]\n";
	print "@_\n";
	exit;
}

sub print_root_usage{
	my $sgusage="$0 --user <username>";
	print "Usage:\n$sgusage\n";
	print "@_\n";
	exit;
}

sub qstat{
	if("$sguser" eq "all"){
		$sguser="'*'";
	}
	open ("qs", "qstat -u $sguser|");
	while(<qs>){
		chomp;
		if(/\s+$sguser\s+r\s+.+$thost.+/){
			@parsejob = split '\s+', $_;
			#
			$status->{jobid} = "$parsejob[1]";
			$status->{user} = "$parsejob[4]";
			$status->{state} = "$parsejob[5]";
			$status->{tsubmit} = "$parsejob[6] $parsejob[7]";
			$status->{queue} = "$parsejob[8]";
			$status->{queue} =~ s/@.+//;
			push(@jobs, "$thost");
			push(@jobs, "$status->{jobid}");
			push(@jobs, "$status->{user}");
			push(@jobs, "$status->{state}");
			push(@jobs, "$status->{tsubmit}");
			push(@jobs, "$status->{queue}");
			$jobID="$status->{jobid}";
		}
	}
}

sub headline{
	printf "%1s %15s %10s %15s %10s %12s %20s %10s %10s %30s", 'Hostname', 'job-ID', 'Tool', 'User', 'State', 'Submit', 'Duration [D:H:M]', 'Queue', 'Slots', 'Memory [In-use/Requested]';
	print "\n";
}

sub getjinfo{
	open("jd", "qstat -j $jobID|");
	while(<jd>){
		chomp;
		if(/command/i){
			my @cmd = split ',', $_;
			foreach (@cmd){
				if(/command/i){
					$command="$_";
					$command =~ s/\w+=//;
				}
			}
		}
		if(/usage\s+/){
			my @usage = split '\s+', $_;
			foreach (@usage){
				if(/maxvmem/){
					$mem="$_";
					$mem =~ s/\w+=//;
					$mem =~ s/,//;
					$mem =~ s/\.\d+//;
				}
				if(/wallclock/){
					$wclock="$_";
					$wclock =~ s/\w+=//;
					$wclock =~ s/:\d+\,//;
				}
			}
		}
		if(/granted_req/){
			my @granted = split '\s+', $_;
			foreach (@granted){
				if(/physical_cpu/){
					$cpu="$_";
					$cpu =~ s/\w+=//;
					$cpu =~ s/,//;
					$cpu =~ s/\.\d+//;
				}
			}
		}
		if(/submit_cmd/){
			my @submit = split ':', $_;
			$qsub="$submit[1]";
			$qsub =~ s/^\s+//;
			my @submitmem = split '\s+', $_;
			foreach (@submitmem){
				if(/pmem/){
					my @tmp = split ',', $_;
					foreach (@tmp){
						if(/pmem/){
							$req_mem="$_";
							$req_mem =~ s/\w+=//;
							$req_mem =~ s/$/G/;
						}
					}
				}
			}
		}
		if(/real_tool_name/i){
			my @tmp = split ',', $_;
			foreach (@tmp){
				if(/real_tool_name/i){
					$toolname="$_";
					$toolname =~ s/\w+=//;
				}
			}
		}
		if(/current_dir/i){
			my @tmp = split ',', $_;
			foreach (@tmp){
				if(/current_dir/i){
					$cdir="$_";
					$cdir =~ s/\w+=//;
				}
			}
		}
	}
}
