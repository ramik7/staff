#!/usr/bin/perl

#====================================================================================================
#package synchronization for VM
#This script should be cron activated.
#should check if VM is active within GM offices, and synchronize needed packages from the NFS space
#log file will be filled.
#
#If the time permits (as I am departing GM) I'll initiate a report by an email for the VM user.
#
#Rami Krankurs
#October 2017
#====================================================================================================

use strict;
#use Capture::Tiny 'capture_merged';

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $nfs="10.90.34.154:/share/MD0_DATA/packages"; #Production	QNAP
my $rdg="10.90.36.1";				 #Refferance Default Gateway
#
my %nfs;
my $log="/local/sync/packages/log";
my $msync="rsync -az --progress --delete --exclude .ignore --exclude .2delete";
my @exclude=("VM", "install", "logstash");
my @excludeall;
my $pcommand="ping $rdg -c 5";
my $dosync="off";
my $nfspkg="/nfs/mnt/pkg";
#
my @dmountp;
my @fmountp;
my @activesync;
my $entry;
my $pname;
my $method;
my $srcdir;
my $dstdir;
my $dlog;
my @linepath;
my $ln;
my $eflg;


foreach (@exclude){
	push @excludeall, "--exclude";
	push @excludeall, "$_";
}

&lancheck;
print "should I sync? $dosync\n";
&synchronize;

sub lancheck{
#To determine where from VM is active is on GM lan, the its okay to start the sync process.
	open(clatency, "$pcommand|");
	while(<clatency>){
		chomp;
		if (/^rtt/){
			use POSIX;
			my @icmpt = split(/\s+/, $_);	
			my @icmpavg = split(/\//, $icmpt[3]);
			my $icmpavg = ceil("$icmpavg[1]");
			if( "$icmpavg" < "10" ){
				$dosync="on";
				if ((-e "$nfspkg")&&(! -d "$nfspkg")){system("rm -f  $nfspkg");}
				if (! -e "$nfspkg"){system("mkdir -p $nfspkg");}
				system("mount -t nfs -o remount,ro $nfs $nfspkg");
				if("$?" ne "0"){system("mount -t nfs -o ro $nfs $nfspkg");}
			}
		}
	}
	close icmp;
}

sub synchronize{
        open (nm,"ls $nfspkg|");
        while(<nm>){
                chomp;
                next if /\@Recycle/;
                $entry="$nfspkg/$_";
		$pname="$_";
		&dolog;
                if(-d "$entry"){
                        push @dmountp, "$entry";
                        #print "DIR $entry\n";
                }
                if(-f "$entry"){
                        push @fmountp, "$entry";
                        #print "FILE $entry\n";
                }
        }
        @dmountp = grep { $_ ne '' } @dmountp;
        @fmountp = grep { $_ ne '' } @fmountp;
        foreach (@dmountp){
		$ln="$_";
		@linepath = split(/\//, $_);
		my $lastent = pop @linepath;

		for my $line (@exclude) {
			if ($line =~ m/$lastent/){
				$eflg="on";
				last;
			}
		}
		if("$eflg" ne "on"){
			$method="rsync";
			$srcdir="$nfspkg/$lastent";
                	&dosync;
		}
		$eflg="off";
        }
	foreach (@fmountp){
		if ("$_" =~ /\//){
			$dstdir="$_";
			$method="cp";
			&dosync;
			#print "$_\n";
		}
	}
}

sub dolog{
        my($day, $month, $year)=(localtime)[3,4,5];
        my $today="$day-".($month+1)."-".($year+1900);
        $dlog="$log/$today";
        if( ! -d "$dlog" ){
                system("mkdir -p $dlog");
        }
}

sub dosync{
	$dstdir=$srcdir;
	$dstdir =~ s/\/nfs\/mnt//;
        open (my $logfile, '>', "$dlog/$pname");
        if("$method" eq "rsync"){
#                print "$msync $srcdir/ $dstdir/\n";
                print $logfile capture_merged { system("$msync $srcdir/ $dstdir/"); };
        }
        else{
#                print "cp -p $srcdir/ $dstdir/\n";
                print $logfile capture_merged { system("cp -p  $srcdir $dstdir"); };
        }
        close $logfile;
}
