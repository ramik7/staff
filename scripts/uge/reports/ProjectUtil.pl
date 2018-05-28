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
my $marshell="PROJ_HOME";
my $mark="env_list";
#=========================

my @ordered;

my $job;
my $project;
my $cpu;
my $rmem;
my $pmem;
my @ajobs;
my $uzer;
my @projects;
my @all;
my @allsorted;
my $gecos;
my $suzer;
my $tfile="/tmp/onef.$$";
my @qstat = `qstat -u '*'`;
my $acct="0";
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
	push(@all, "$job:$suzer:$project:$rmem:$pmem:$cpu");	#JOB:USER:PROJECT:MEM_REQ:MEM_IN_USE:CPU
}
&psort3;
&dotable;
&gwpage;

sub getprjinfo{
	my @tmp=`qstat -j $job`;
	foreach(@tmp){
		chomp;
		if(/^owner/){
			my @tmp = split ':', $_;
			$uzer="$tmp[1]";
			$uzer =~ s/\s+//g;
			&ldapq($uzer);
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
					my $projectmp="$tmp2[1]";
					my @tmp3 = split '/', $projectmp;
					$project="$tmp3[2]";
				}
			}
		}
	}
}

sub ldapq{
	my $lpattern="cn";
        my $ldaps="ldapsrv501";
        my $ldapline="uid=$uzer,ou=people,o=il.marvell.com,dc=marvell,dc=com objectClass=posixaccount return $lpattern";
        open(LDAP, "ldapsearch -LLL -x -h $ldaps -b $ldapline|");
        while(<LDAP>){
                chomp;
                if(/$lpattern/){
                        s/$lpattern\:\s+//;
                        $gecos="$_";
                }
        }
	if("M$gecos" eq "M"){
        	$suzer="$uzer";
	}
	else{
        	$suzer="$gecos ($uzer)";
	}
	$gecos="";
}

sub psort3{
	use Sort::Fields;
	@allsorted = fieldsort '\:', [3], @all;
	#foreach(@sorted){
	#	print "$_\n";
	#}
}

sub dotable{
        open STDOUT, '>', "$tfile";
        my @headline=("Job-ID", "User", "Project", "Memory Requested", "Memory In-Use", "Slots");
        my $rows=($acct*3)+1;
        my $col=scalar @headline;
        use HTML::Table;
        my $table1 = new HTML::Table(-rows=>$rows, -cols=>$col, -border=>5);
        my $cellcol="1";
        foreach(@headline){
                $table1->setRowBGColor(1, "#037CD6");
                $table1->setCell(1, $cellcol, "<b>$_</b>");
                $cellcol++;
        }
        $cellcol="1";
        my $counter="2";
        foreach(@allsorted){
                #print "$_\n";
                #R#my @tmp = split '\s+', $_;
                my @tmp = split ':', $_;
                if("$_" !~ "]"){
                        $cellcol="1";
                        foreach(@tmp){
                                #R#$table1->setRowBGColor($counter, "#98E8DA");
                                $table1->setRowBGColor($counter, "#AED6F1");
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
                                $table1->setRowBGColor($counter, "#AED6F1");
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
        my $html="/unix_srv/local/reports/OneFlow/dc3proj.html";
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
