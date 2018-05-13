#!/unix_srv/pkg/marvell/software/perl/5.26.1/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

#OneFlow(DC3), UGE83, UGE854
#Generate swgrp_server.lst
#This script will modify the file with the updated HPC (OneFlow) list.

#Rami Krankurs
#March 2018, Marvell

use Env::Path;
use strict;
use warnings;
use Getopt::Long;
use List::MoreUtils qw(uniq);
#
#================== Settings ====================
#Modify Only Here
#
my $production="/mnt/projadmin/swgrp_server.lst";
my $pfile="swgrp_server.lst";
my $checkout="co -l $pfile";
my $checkin="ci -u $pfile";
my $stage="/mnt/projadmin/swgrp_server.lst.stage";
my @ah;
my @nrvs;
my @esend;
my $ENV;
my $hpcf="";
my $rhpcf="";
#
my @addlist = ("ramik","dimad","tanya");
#
my $jnow = localtime;
#
#my @gv=("83", "854");
my @gv=("854");
my %gv;
#$gv{83} = \&uge83;
$gv{854} = \&uge854;

sub uge83{
	$ENV->{SGE_ROOT} = "/proj/sge/uge83";
	$ENV->{SGE_CELL} = "UREDA";
	$ENV->{SGE_CLUSTER_NAME} = "DC3_UREDA";
	$ENV->{SGE_PATH} = "/proj/sge/uge83/bin/lx-amd64";
	$ENV->{SGE_QMASTER_PORT} = "6487";
	$ENV->{SGE_EXECD_PORT} = "6488";
	#=================================================
	$ENV{SGE_ROOT}="$ENV->{SGE_ROOT}";
	$ENV{SGE_CELL}="$ENV->{SGE_CELL}";
	$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";
	$ENV{SGE_PATH}="$ENV->{SGE_PATH}";
	$ENV{SGE_QMASTER_PORT}="$ENV->{SGE_QMASTER_PORT}";
	$ENV{SGE_EXECD_PORT}="$ENV->{SGE_EXECD_PORT}";
	#=================================================
}
#
sub uge854{
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
}
#
foreach(@gv){
	$gv{"$_"}->();
	Env::Path->PATH->Prepend("$ENV->{SGE_PATH}");
	&gethostlist;
}
#
sub gethostlist{
	open ("ahosts", "qhost|");
	while(<ahosts>){
		chomp;
		if(/amd64/){
			my @tah = split '\s+', $_;
			push(@ah, "$tah[0]");
		}
	}
	close "ahosts";
}
my %dup=();
my @ahs = grep { ! $dup{$_} ++ } @ah;
@ah=@ahs;
&do_generate;
&manage;

sub do_generate{
	if (-e "$stage" ){
		system("rm -f $stage");
	}
	open("prod","$production");
	open("stage2",">$stage");
	while(<prod>){
		chomp;
		if(/HPC-start/){
			print stage2 "$_\n";
			$hpcf="on";
		}
		if(/HPC-end/){
			$hpcf="off";
		}
		if(("$hpcf" eq "on")&&("$rhpcf" ne "on")){
                        foreach(@ah){
                                print stage2 "$_\n";
                        }
			$rhpcf="on";
                }
		if("$rhpcf" ne "on"){
			print stage2 "$_\n";
		}
		if(("$hpcf" eq "off")&&("$rhpcf" eq "on")){
			print stage2 "$_\n";
		}
	}
	close "stage2";
	close "prod";
}
sub manage{
	use File::Compare;
	use Rcs;
	use File::Copy;
	open STDERR, '>/dev/null';
	system("rcs -u $production");
	close STDERR;
	my $swgrf = Rcs->new;
	Rcs->bindir('/usr/bin');
	$swgrf->workdir('/mnt/projadmin');
	$swgrf->rcsdir("/mnt/projadmin/RCS");
	$swgrf->file("$pfile");
	if (compare("$production", "$stage") != 0) {
		$swgrf->co('-l');
		copy("$stage","$production") or die "Copy failed: $!";
		$swgrf->ci('-u', '-mRevision Comment');
		#Compare 2 last RCS revisions
		my @rlogc = $swgrf->rlog;
		foreach(@rlogc){
			chomp;
			if(/^revision\s+/){
				my @rvs = split '\s+', $_;
				foreach(@rvs){
					if(/\d+/){push(@nrvs, "$_");}
				}
			}
		}
		my $cur="$nrvs[0]";
		my $pre="$nrvs[1]";
		my @rdiff = $swgrf->rcsdiff("-r\"$cur\"", "-r\"$pre\"");
		push(@esend, "<b><u>$jnow</u></b><br>");
		foreach(@rdiff){
			if(/>/){
				$_ =~ s/>//;
				push(@esend, "deleted <font color=#0000ff><b>$_</b></font color><br>");
				print "deleted $_";
			}
			if(/</){
				$_ =~ s/<//;
				push(@esend, "added <font color=#0000ff><b>$_</b></font color><br>");
				print "added $_\n";
			}
		}
		&notify;
	}
}

sub notify{
	use Net::SMTP;
	my $mailg="mail.il.marvell.com";
	my $smtp = Net::SMTP->new("$mailg");
	my $subject="$pfile changes";
	my $domain="marvell.com";
	$smtp->mail("Marvell-Report\@marvell.com");
	foreach(@addlist){
		$smtp->to("$_\@marvell.com");
	}
	$smtp->to("@addlist");
	$smtp->data();
	$smtp->datasend("Subject: $subject\n");
	#$smtp->datasend("To: $rcpt\@$domain");
	$smtp->datasend("Content-Type: text/html\n");
	$smtp->datasend("<html><head></head><body>");
	$smtp->datasend("@esend\n\n");
	$smtp->datasend("</body></html>");
	$smtp->dataend();
	$smtp->quit();
}
