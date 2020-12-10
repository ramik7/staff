#!/tools/perl/centos/7/5.32.0/bin/perl

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

#generates JSON data from hosts
#modified for Valens
#rami.krankurs@valens.com

use Env::Path;
use Package::Stash;
use strict;
use warnings;
use Getopt::Long;
use List::MoreUtils qw(uniq);
use File::Slurp;

my $debug="no";;
my $diventory="/tools/local/inventory";
my @jsonf;

if (("$#ARGV" == "0")&&("$ARGV[0]" eq "-d")){
        $debug="yes";
}

my $hname;              # => Hostname
my $distributor;        # => OS Distributor
my $rel;                # => OS Release
my $arch;               # => OS Architecture
my $vendor;             # => Vendor Name
my $tmem;               # => Memory (total)
my $soc;                # => CPU (number of processors)
my $cores;              # => CPU (number of cores)
my $cpu;                # => CPU (processor version)
my $DC;                 # => Data Center
my $serial;             # => Serial Number
my $IP;                 # => IP Address
my $GW;                 # => GW Address
my $mac;                # => HW (MAC) address
my $kernel;             # => Kernel version
my $up;                 # => Server's uptime
my $hid;                # => HostID
my $product;		# => Product Name
my $ds;			# => Days/Hours (uptime measurement unit)
my $biosd;		# => BIOS release date
my $htt="off";		# => Processor Multi-threading 
my $htc;		# => Core max temperature

$hname=`uname -n`;
chomp $hname;
my $type="";
my $sfile="$diventory/stage/$hname.$$";

use DateTime;
my $mtz='Asia/Jerusalem';
my $dt = DateTime->now(time_zone => "$mtz");
$dt =~ s/T/ /;
$dt =~ s/:\d+$//;

gethinfo();
marry();
djson();

$type="vgeneral";
my $file="$diventory/$type/$hname";
$file =~ s/\s+//;
system("mv $sfile $file");

sub marry{
	push(@jsonf, "  hostname : \"$hname\",");
	push(@jsonf, "  distributor : \"$distributor\",");
	push(@jsonf, "  release : $rel,");
	push(@jsonf, "  arch :  \"$arch\",");
	push(@jsonf, "  vendor :  \"$vendor\",");
	push(@jsonf, "  memory :  \"$tmem\",");
	push(@jsonf, "  soc : $soc,");
	push(@jsonf, "  CPU_MT :  \"$htt\",");
	push(@jsonf, "  cores : $cores,");
	push(@jsonf, "  max_temp : $htc,");
	push(@jsonf, "  cpu :  \"$cpu\",");
#	push(@jsonf, "  DC :  \"$DC\",");
	push(@jsonf, "  serial :  \"$serial\",");
	push(@jsonf, "  IP :  \"$IP\",");
	push(@jsonf, "  GW :  \"$GW\",");
	push(@jsonf, "  mac :  \"$mac\",");
	push(@jsonf, "  kernel :  \"$kernel\",");
	push(@jsonf, "  uptime :  \"$up $ds\",");
	push(@jsonf, "  hostid :  \"$hid\",");
	push(@jsonf, "  product :  \"$product\",");
	push(@jsonf, "  BIOS_Release_Date :  \"$biosd\",");
	push(@jsonf, "  Last_Update :  \"$dt\",");
}

sub djson{
	open("json", ">$sfile");
	print json "{\n";
	chomp @jsonf;
	s/\"\s+/"/ for @jsonf;
	s/\s+\"/"/g for @jsonf;
	s/^\"/  "/g for @jsonf;
	s/":/": /g for @jsonf;
	$jsonf[-1] =~ s/,$//g;
	foreach(@jsonf){
		print json "$_\n";
	}
	print json "}\n";
}


sub gethinfo{
#generates host data.
	gbiosd();
	getserial();
	my @rt=`route`;
	foreach(@rt){
		chomp;
		if(/default/){
			my @tmp=split('\s+', $_);
			$GW="$tmp[1]";
		}
	}
	gmac();
	use Math::Round;
	my @up=`cat /proc/uptime`;
	foreach(@up){
		chomp;
		my @tmp=split('\s+', $_);
		$up="$tmp[0]";
		$up/=3600;
		if("$up" > 48){
			$up/=24;
			$up=round($up);
			$ds="D";
		}
		else{
			$up=round($up);
			$ds="H";
		}
	}

	my $pcount="0";
	$arch=`uname -i`;
	chomp $arch;
	$hid=`hostid`;
	chomp $hid;
	$kernel=`uname -r`;
	chomp $kernel;
	my $pf="off";
	my $si="off";
	my @ddecode=`sudo dmidecode`;
	foreach(@ddecode){
		chomp;
		if(/system\s+information/i){
			$si="on";
		}
		if(("$si" eq "on")&&(/manufacturer/i)){
			my @tmp=split(':', $_);
			$vendor="$tmp[1]";
			$si="off";
		}
		if(/product\s+name/i){
			my @tmp=split(':', $_);
			$product="$tmp[1]";
			$product =~ s/\s+/_/g;
			$product =~ s/^_//;
		}
		if(/processor\s+information/i){
			$pf="on";
			$pcount++;
		}
		if(("$pf" eq "on")&&(/version/i)){
			my @tmp=split(':', $_);
			$cpu="$tmp[1]";
			$cpu =~ s/\s+/_/g;
			$cpu =~ s/^_//;
			$cpu =~ s/_$//;
			$pf="off";
		}
		if(/Multi-threading/){
			$htt="on";
		}
	}
	$soc="$pcount";
	if(echeck("lsb_release")){
		my @lsb=`lsb_release -a`;
		foreach(@lsb){
			chomp;
			if(/^distributor\sid/i){
				my @tmp=split(':', $_);
				$distributor="$tmp[1]";
			}
			if(/^release/i){
				my @tmp=split(':', $_);
				$rel="$tmp[1]";
			}
		}
	}
	if(echeck("hostnamectl")){
		my @hostnamectl=`hostnamectl`;
		foreach(@hostnamectl){
			chomp;
			if(/static\shostname/i){
				my @tmp=split(':', $_);
				$hname="$tmp[1]";
			}
		}
	}
	else{
		$hname=`uname -n`;
	}
	my $ccount="0";
	my @cpuinfo=`cat /proc/cpuinfo`;
	foreach(@cpuinfo){
		chomp;
		if(/^processor/){$ccount++}
	}
	$cores="$ccount";
	my @meminfo=`cat /proc/meminfo`;
	foreach(@meminfo){
		chomp;
		if(/^memtotal/i){
			my @tmp=split(':', $_);
			$tmem="$tmp[1]";
			$tmem =~ s/kB//;
			$tmem/=1048576;
			$tmem=round($tmem);
			$tmem="$tmem GB";
		}
	}
	sensors();
}

sub echeck{ 
	use File::Which;
	my $echk="@_";
	my $wc = which "$echk";
}

sub getserial{
#generates host serial number
	my @serial=`sudo dmidecode -s system-serial-number`;
	foreach(@serial){
        	chomp;
		if(/vmware/i){$serial="vmware";}
		else{$serial="$_";}
	}
}

sub gmac{
#generates host active network interface HW (MAC) address
	my $link;
	my @IP=`ip link ls up`;
	foreach(@IP){
		chomp;
		if(((/\d+\:\s+.*LOOPBACK.*/)||(/\d+\:\s+.*NO-CARRIER*/)||(/\d+\:\s+.*,SLAVE,.*/))){
			$link="off";
		}
		if(("$link" eq "off")&&(/link/)){
			$link="";
		}
		if((/\d+\:\s+.*BROADCAST,MULTICAST.*,UP.*/)&&("$link" ne "off")){
			$link="on";
			my @tmp=split(':', $_);
			my $inter="$tmp[1]";
			my @ifconfig=`ifconfig $inter`;
			foreach(@ifconfig){
				chomp;
				if(/inet\s+/){
					my @tmp=split('\s+', $_);
					$IP="$tmp[2]";
					$IP=~s/addr\://;
				}
			}
		}
		if(("$link" eq "on")&&(/link/)){
			my @tmp=split('\s+', $_);
			$mac="$tmp[2]";
		}
	}
}

sub gbiosd{
#generates host bios data
	my @bios=`sudo dmidecode -t bios`;
	foreach(@bios){
		chomp;
		if(/release\s+date/i){
			my @tmp=split(':', $_);
			$biosd="$tmp[1]";
		}
	}
}

sub sensors{
	my $ctype="";
	use List::Util;
	use POSIX qw/ceil/;
	my $trashold="85";
	my @coretemp;
	if("sensors"){
		my @ctemp=`sudo sensors`;
		if("$cpu" =~ /AMD/){
			foreach(@ctemp){
                        	chomp;
                        	next if (! /Ecore/i);
                        	next if ( ! /\d+\..*kJ/ );
                        	my @tmp=split;
                        	my $temp = "$tmp[1]";
                        	$temp =~ s/\+//;
                        	$temp =~ s/\..*//;
                        	push(@coretemp, "$temp");
			}
		}
		else{
			foreach(@ctemp){
				chomp;
				next if (! /core/i);
				next if ( ! /\d+\..*C/ );
				my @tmp=split;
				my $temp = "$tmp[2]";
				$temp =~ s/\+//;
				$temp =~ s/\..*//;
				push(@coretemp, "$temp");
			}
		}
	}
	@coretemp = sort { $a <=> $b } @coretemp;
	$htc = pop(@coretemp);
	if("$cpu" =~ /AMD/){
		$htc = ceil($htc * 0.5266);
	}
}
