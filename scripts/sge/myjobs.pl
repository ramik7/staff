#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

#OneFlow(DC3), UGE83
#show user active jobs

#Rami Krankurs
#March 2018, Marvell

use Env::Path;
use strict;
use warnings;
use Getopt::Long;
#
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
my $uge="";

GetOptions(
	'--user=s' => \$sguser,
	'--env=s' => \$uge)
or die(&print_usage);

my $ENV;
&cgrid;
$ENV{SGE_ROOT}="$ENV->{SGE_ROOT}";
$ENV{SGE_CELL}="$ENV->{SGE_CELL}";
$ENV{SGE_CLUSTER_NAME}="$ENV->{SGE_CLUSTER_NAME}";
$ENV{SGE_QMASTER_PORT}="$ENV->{SGE_QMASTER_PORT}";
$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";
Env::Path->PATH->Append("$ENV->{SGE_PATH}");

if(("$me" eq "root")&&("$sguser" eq "root")){
	&print_root_usage;
}
if((! defined $sguser)||(! defined $me)){
        &print_usage;
}

open ("ahosts", "qhost|");
while(<ahosts>){
	chomp;
	if(/amd64/){
		@tah = split '\s+', $_;
		push(@ah, "$tah[0]");
	}
}
close "ahosts";

&headline;
print "-"x145,"\n";
foreach (@ah){
	$rf="";
	$thost="$_";
	open ("jl","qhost -j -h $_|");
		while(<jl>){
		chomp;
		if(/\s+\b$sguser\b\s+r\s+/){
			$rf="r";
			&qstat;
			&getjinfo;
		}
	}
	if("$rf" eq "r"){
		$jf="on";
		if("M$jobID" ne "M"){
			printf ("%1s %13s %13s %12s %9s %21s %10s %12s %10s %15s",$jobs[1],$jobs[2],$toolname,$jobs[3],$jobs[4],$jobs[5],$wclock,$jobs[6],$cpu,"$mem/$req_mem");
			if("M$command" eq "M"){$command="$qsub";}
			print "\n";
			printf ("%1s %10s","Working Dir:","[$cdir]");
			print "\n";
			printf ("%1s %10s","Command:","[$command]");
			print "\n";
			print "-"x145,"\n";
		}
	}
	close "jl";
	@jobs="";
}
print "\n";
if("$jf" ne "on"){print "-No Active Jobs for $sguser.\n";}

sub print_usage{
	my $sgusageme="$0";
	my $sgusage="$0 --user <username> --env <u83|misl>";
	print "Usage:\n$sgusageme [Yourself]\n== OR ==\n$sgusage --user <username> [Any other user] --env <u83 [DC3] OR misl>\n";
	print "@_\n";
	exit;
}

sub print_root_usage{
	my $sgusage="$0 --user <username> --env <u83|misl>";
	print "Usage:\n$sgusage\n";
	print "@_\n";
	exit;
}

sub qstat{
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

sub cgrid{
	if("$uge" eq "misl"){
		$ENV->{SGE_ROOT} = "/uge/ncd/current";
		$ENV->{SGE_CELL} = "misl_ncd";
		$ENV->{SGE_CLUSTER_NAME} = "misl6460";
		$ENV->{SGE_QMASTER_PORT} = "6460";
		$ENV->{SGE_EXECD_PORT} = "6461";
		$ENV->{SGE_PATH} = "/uge/ncd/current/bin/lx-amd64";
	}
	else{
		$ENV->{SGE_ROOT} = "/proj/sge/uge83";
		$ENV->{SGE_CELL} = "UREDA";
		$ENV->{SGE_CLUSTER_NAME} = "DC3_UREDA";
		$ENV->{SGE_QMASTER_PORT} = "6487";
		$ENV->{SGE_EXECD_PORT} = "6488";
		$ENV->{SGE_PATH} = "/proj/sge/uge83/bin/lx-amd64";
	}
}
