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
use set_fcd;
Env::Path->PATH->Prepend("$ENV{SGE_PATH}");

use List::MoreUtils qw(uniq);
use POSIX;

#=========================
my $marshell="sge_marshell_command";
my $mark="env_list";
#=========================

my $job;
my $project;
my $cpu;
my $rmem;
my $pmem;
my @ajobs;
my @data;
my $uzer;
my @projects;
my @all;
my $tempdbf;
my @qstat = `qstat -u '*'`;
my $acct="0";
my $tfile="/tmp/fcd.$$";
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
	push(@all, "$uzer:$job:$project:$rmem:$pmem:$cpu");	#JOB:PROJECT:MEM_REQ:MEM_IN_USE:CPU
}

#R#&psort;
&dotable;
&gwpage;
system("rm -f $tfile");

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
		if(/OBS-granted_req/){
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
			$rmem =~ s/G//;
			$rmem=ceil($rmem);
			$rmem =~ s/$/G/;
			$cpu =~ s/\s+//; #=> REQ CORE
		}
		if(/^hard\s+resource_list/){
			my @tmp = split ',', $_;
			foreach(@tmp){
				if(/mem_free/){
					my @tmp1 = split '=', $_;
					$rmem="$tmp1[1]";
					$rmem =~ s/g/G/;
				}
			}
		}
		if(/^usage/){
			my @tmp = split ',', $_;
			my @pmem = split ',', $tmp[7];
			my @cpu = split '\s+', $_;
			my $cores="$cpu[1]";
			$cores =~ s/\://;
			$cpu=$cores;
			$pmem = join "", @pmem;
			$pmem =~ s/pmem=//;
			$pmem =~ s/\s+//;
			my $psf=$pmem;
			$psf =~ s/\d+.\d+//;
			$psf =~ s/maxvmem=//;
			my $suff="$pmem";
			my $g="G";
			my @tmp = split '=', $suff;
			$pmem="$tmp[1]";
			$pmem=ceil($pmem);
			if("$pmem" == "0"){
				$pmem="No Data";
			}
			else{
			#----------------
				$pmem="$pmem$psf"; #=> MEM USAGE
			}
		}
		if(/$mark/){
			my @tmp = split ',', $_;
			foreach(@tmp){
#				print "LLL $_\n";
				if(/$marshell/i){
					my @tmp2 = split '=', $_;
					$project="$tmp2[1]";
#					print "MARK $project\n";
				}
			}
		}
	}
}

sub psort{
	foreach(@all){
		print "$_\n";
	}
}

sub dotable{
        open STDOUT, '>', "$tfile";
        my @headline=("Username", "job-ID", "Command", "Memory Requested", "Memory In-Use", "Slots");
        my $rows=($acct*3)+1;
        my $col=scalar @headline;
        use HTML::Table;
        my $table1 = new HTML::Table(-rows=>$rows, -cols=>$col, -border=>5);
        my $cellcol="1";
        foreach(@headline){
                #R#$table1->setRowBGColor(1, "#AED6F1");
                $table1->setCell(1, $cellcol, "<b>$_</b>");
                $cellcol++;
        }
        $cellcol="1";
        my $counter="2";
        foreach(@all){
                #print "$_\n";
                #R#my @tmp = split '\s+', $_;
                my @tmp = split ':', $_;
                if("$_" !~ "]"){
                        $cellcol="1";
                        foreach(@tmp){
                                #R#$table1->setRowBGColor($counter, "#98E8DA");
                                $table1->setCell($counter, $cellcol, "$_");
                                $cellcol++;
                        }
                $counter++;
                }
                else{
                        if("$_" =~ /\[/){
                                s/WD/Working Directory: /;
                                s/CMD/Command: /;
                                #R#$table1->setRowBGColor($counter, "#8BCABF");
                                $table1->setCellColSpan($counter, 1, $col);
                                $table1->setCell($counter, 1, "$_");
                        }
                        $counter++;
                }
        }
        $table1->print;
        close STDOUT;
}

sub gwpage{
        my @page;
        my $html="/unix_srv/local/reports/OneFlow/misl_fct.html";
        #R#my $html="/tmp/misl_fct.html";
        push(@page, "<html><head></head><body>");
        push(@page, "<meta http-equiv=");
        push(@page, "\"refresh\"");
        push(@page, " content=\"5\">");
        open("tfile", "$tfile");
        while(<tfile>){
                push (@page, "$_");
        }
        close "tfile";
        push(@page, "</body></html>");
        open STDOUT, '>', "$html";
        foreach(@page){
                print "$_";
        }
}
