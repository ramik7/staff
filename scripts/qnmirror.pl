#!/pkg/perl/5.26.0/bin/perl

#QNAP mirror for AV, GM Hertzliya
#Rami Krankurs
#September 2017

use strict;
use autodie;
use Capture::Tiny 'capture_merged';

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $src="10.90.34.154"; #Production	QNAP
my $dst="10.90.34.204"; #Stage		QNAP
#
my %nfs;
my $log="/prj/local/qmirror/log";
my $mounts="/proc/mounts";
my $msync="rsync -az --progress --delete --exclude .ignore --exclude .2delete";
my @dmountp="";
my @fmountp="";
my $srcdir="";
my $dstdir="";
my $mountent="";
my $dlog="";
my $method="";
my $exclude="data";

open (fstab,"/etc/fstab");
while(<fstab>){
	chomp;
	next if /\/$exclude/;
	next unless (/^$src/);
	my @fsline = split(/\s+/, $_);
	$nfs{"$fsline[1]"} = "$fsline[0]";
	my $rmountp="$fsline[1]";
	my $mountp="$fsline[1]";
	$mountp =~ s/\///;
	$mountp =~ s/\//_/;
	my @mountp="$mountp";
	$mountent="$mountp";
	@dmountp=@mountp;
	@fmountp=@mountp;
	&do_log;
	open (nm,"ls $rmountp|");
	while(<nm>){
		chomp;
		next if /\@Recycle/;
		my $entry="$rmountp/$_";
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
		if ("$_" =~ /\//){
			$srcdir="$_";
			$method="rsync";
			&do_sync;
			#print "$_\n";
		}
	}
	foreach (@fmountp){
		if ("$_" =~ /\//){
			$dstdir="$_";
			$method="cp";
			&do_sync;
			#print "$_\n";
		}
	}
}
close fstab;

my @qnfs = keys %nfs;

foreach (@qnfs){
	my $mflag="";
	my $dsexp="$nfs{$_}";
	$dsexp =~ s/$src/$dst/;
	my $dmnt="/mnt$_";
	if ( ! -d "$dmnt" ){
		system("mkdir -p $dmnt");
	}
	open (checkm,"$mounts");
	while(<checkm>){
		chomp;
		if (/$dsexp/){$mflag="on"; last;}
	}
	close checkm;
	if("$mflag" ne "on"){
		system("mount -t nfs $dsexp $dmnt");
	}
}

sub do_log{
	my($day, $month, $year)=(localtime)[3,4,5];
	my $today="$day-".($month+1)."-".($year+1900);
	$dlog="$log/$today/$mountent";
	if( ! -d "$dlog" ){
		system("mkdir -p $dlog");
	}
}

sub do_sync{
	$dstdir="/mnt$srcdir";
	my $fslog="$dlog/$_";
	$fslog =~ s/\/_/\//;
	$fslog =~ s/\/\//\//;
	$fslog =~ s/data\//data_/;
	$fslog =~ s/$mountent\/$mountent/$mountent/;
	open (my $logfile, '>', "$fslog");
	if("$method" eq "rsync"){
		#print "$msync $srcdir/ $dstdir/\n";
		print $logfile capture_merged { system("$msync $srcdir/ $dstdir/"); };
	}
	else{
		#print "cp -p $srcdir/ $dstdir/\n";
		print $logfile capture_merged { system("cp -p  $srcdir $dstdir"); };
	}
	close $logfile;
}
