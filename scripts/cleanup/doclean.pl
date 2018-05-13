#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin";

#Cleans /tmp space, while leaving active jobs, hardcoded excludes intact.
#
#Rami Krankurs, Marvell
#April 2018

use strict;
use Sys::Hostname;

#===============================================================
#Modify only here
#
my $szlimit=10;	#defines which /tmp percentage triggers cleanup.
my $keep="8";	#number of DAYS to keep /tmp data
my $exclist="/unix_srv/ittools/clean_tmp/exclude";	#excluded patterns. 
#===============================================================
#
#R#my $logfile="/unix_srv/ittools/clean_tmp/log/report";
#
my $excludehosts="/unix_srv/ittools/clean_tmp/etc/exclude_file";
my $logfile="/tmp/tmpcln.log";
my $host=hostname;
my $dir="/tmp";
my $df="df -h";
my $psz;
my @userlist;
my @tmpd;
my $asz;
my $filename;
my $mark;
my $cinc;
my $exflag="";
my $sdate;
my $dry="";

&getsrgv;
&cife;		# check if it's run on excluded host.
&checktmpsz;	# get /tmp capacity percentage
&getuserlist;
if ("$psz" > "$szlimit"){
	&getdatasize;
	&gdate;
	&doclean;
}

sub cife{
	open("exl", "$excludehosts");
	while(<exl>){
		chomp;
		if("$host" eq "$_"){exit;}
	}
}
sub checktmpsz{
	open("chk", "$df $dir|");
	while(<chk>){
		chomp;
		next if /filesystem/i;
		my @ta = split '\s+';
		$psz="$ta[4]";
		$psz =~ s/\%//;
	}
}
sub doclean{
	use POSIX;
	open(clnf, ">>$logfile");
	print clnf "=" x 25, "\n";
	print clnf "\t$sdate\n";
	print clnf "=" x 25, "\n";
	my $now = time();
	my $days = 14;
	my $spd = 60*60*24;	# seconds in a day
	my $age = $days*$spd;	# age in seconds
	my $method;
	print "\nremoving the following /tmp files:\n";
	foreach(@tmpd){
		my @filedata=stat("$dir/$_");
		my $filemode="$filedata[2]";
		my $mtime="$filedata[9]";
		my $ctime="$filedata[10]";
		my $fage = time() - $mtime;
		my $dayz = $fage / $spd;
		$dayz = ceil($dayz);
		if(-d "$dir/$_"){
			$method="rm -rf";
		}
		else{
			$method="rm -f";
		}
		$cinc="$_";
		$exflag="off";
		checkexclude("$cinc");
		if(("$exflag" ne "on")&&("$keep" < "$dayz")){
			system("$method $dir/$cinc");
			print "deleting $dir/$cinc\n";
			print clnf "deleting $dir/$cinc\n";
		}
	}
}
sub getuserlist{
	use List::MoreUtils qw(uniq);
        my $ps="ps aux";
	open("process","$ps|");
	while(<process>){
		chomp;
		next if /^user/i;
		my @process = split '\s+';
		push (@userlist, "$process[0]");
	}
	@userlist = uniq @userlist;
}
sub getdatasize{
	use Filesys::DiskUsage qw/du/;
	my @tmpd1;
	open("list", "ls $dir|");
	while(<list>){
		chomp;
		$filename = "$_";
		if ("$filename" =~ 'lost\+found'){next;}
		if(/_\d+_/){
			@tmpd1 = split '_';
			foreach (@tmpd1){
				if (/^\d+$/){
					my $exists = kill 0, $_;
					if (! $exists ){
						push(@tmpd, "$filename");
					}
					else{
						print "$_, Process is running, cannot delete $filename \n";
					}
				}
			}
		}
		if(/\d+\.\d{1}\.\w+/){
			@tmpd1 = split '\.';
			$asz = scalar @tmpd1;
			$mark="first";
			checkme(\@tmpd1);
		}
		if(/\.\d+$/){
			@tmpd1 = split '\.';
			$asz = scalar @tmpd1;
			$mark="last";
			checkme(\@tmpd1);
		}
		if(/\d+\.\d{1}\.\w+/){
			@tmpd1 = split '\.';
			$asz = scalar @tmpd1;
			$mark="first";
			checkme(\@tmpd1);
		}
		if((((! /_\d+_/)&&(! /\d+\.\d{1}\.\w+/)&&(! /\.\d+$/)&&(! /\d+\.\d{1}\.\w+/)))){
			push(@tmpd, "$_");
		}
	}
	my $total;
	$total = du ( { 'Human-readable' => 1 } , $dir );
}
sub checkme{
	use Proc::ProcessTable;
	my @tmp = @{$_[0]};
	my $aszi=$asz-1;
	my $exists;
	foreach(@tmp){
		my @tmp1 = split '\s+';
		my @filename;
		foreach(0..$aszi){
			push(@filename, "$tmp[$_]");
		}
		$filename="@filename";
		$filename =~ s/\s+/\./g;
		if (! /^\d+$/){
			if("$mark" eq "last"){
				$exists = kill 0, $tmp[$aszi];
			}
			if("$mark" eq "first"){
				$exists = kill 0, $tmp[0];
				my $t = new Proc::ProcessTable;
				foreach my $p ( @{$t->table} ){
					foreach my $f ($t->fields){
						if("$p->{$f}" =~ "$tmp[0]"){
							$exists="1";
							last;
						}
					}
				}
			}
			if (! $exists ){
				push(@tmpd, "$filename");
			}
			else{
				if ("$tmp[0]" =~ /\d+/){
					print "$tmp[0], Process is running, cannot delete $filename \n";
				}
				else{
					print "$tmp[1], Process is running, cannot delete $filename \n";
				}
			}
		}
	}
}
sub checkexclude{
	open(exclf, "$exclist");
	while(<exclf>){
		chomp;
		if("$_" eq "$cinc"){
			$exflag="on";
		}
	}
}

sub gdate{
	my $datestring = localtime();
	my @date = split('\s+', $datestring);
	$sdate = "$date[2]-$date[1]-$date[4]";
}
sub getsrgv{
	if(("$#ARGV" == "0")&&("$ARGV[0]" eq "--debug")){
		print "Running dry-run, will not remove data\n";
		$dry="on";
	}
	if(("$#ARGV" == "0")&&("$ARGV[0]" eq "--help")){
		my $filename = shift or die "Usage: Execute with $0 <enter> OR $0 --debug (will not remove data)\n";
		print "filename \n";
	}
	if(("$#ARGV" == "0")&&("$ARGV[0]" ne "--debug")){
		my $filename = shift or die "Usage: Execute with $0 <enter> OR $0 --debug (will not remove data)\n";
		print "filename \n";
	}
}
