#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

$ENV{PATH}="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

my $input;
my $output;
my $classify="0";
my $sort="0";
my $uniq="0";

GetOptions(
	'--classify' => \$classify,
	'--input_folder=s' => \$input,
	'--output_folder=s' => \$output,
	'--sort' => \$sort,
	'--unique' => \$uniq)
or die(&print_usage);

sub print_usage{
	my $clusage="$0 --classify --input_folder <path_to_folder> --output_folder <path_to_folder>";
	my $unusage="$0 --classify --input_folder <path_to_folder> --output_folder <path_to_folder> --unique";
	my $srusage="$0 --sort --input_folder <path_to_folder> --output_folder <path_to_folder>";
	print "Usage:\n$clusage\n$unusage\n$srusage\n";
	print "@_\n";
	exit;
}

if((! defined $input)||(! defined $output)){
	&print_usage("\nPlease specify: --input_folder <path_to_folder> --output_folder <path_to_folder>");
}
my $decvalue = oct( "0b$classify$uniq$sort" );

if(("$decvalue" != "1")&&("$decvalue" != "4")&&("$decvalue" != "6")){
	&print_usage;
}

if(! -d "$input"){die "$input does not exit\n";}
if(! -R "$input"){die "$input cannot access\n";}
if(! -d "$output"){mkdir($output, 0755);}

my @ppl="";
my @ppt="";
my @tetc="";
my @spool="";
my @rpool="";
my @urpool="";
my @srpool="";

if("$sort" eq "0"){
	open(PP, ">$output/people.txt");
	open(PT, ">$output/pets.txt");
	open(ETC, ">$output/other.txt");
	opendir my $indata, $input or die "Could not open '$input' for reading '$!'\n";
	while (my $filename = readdir $indata) {
		next if (-d "$input/$filename");
		next if (! -T "$input/$filename");
		next if (! -R "$input/$filename");
		my $IF="$input/$filename";
		open("ifile", "$IF");
		while(<ifile>){
			chomp;
			push (@rpool, "$_");
			my @ld = (split /\s+/, $_);
			my $length=scalar(@ld);
			if(("$ld[0]" =~ /^[A-Z]/)&&("$length" > 1)){
				push (@ppl, "$_");
			}
			if(("$length" == 1)&&("$_" =~ /^[A-Z]/)){
				push (@ppt, "$_");
			}
			if("$_" =~ /^[a-z]/){
				push (@tetc, "$_");
			}
		}
		close ("ifile");
	}
	&temparray;
	if("$uniq" == "1"){
		my %dup=();
		my @uppl = grep { ! $dup{$_} ++ } @ppl; @ppl=@uppl;
		my @uppt = grep { ! $dup{$_} ++ } @ppt; @ppt=@uppt;
		my @utetc = grep { ! $dup{$_} ++ } @tetc; @tetc=@utetc;
	}
	my @gpool;
	foreach(@ppl){if("Q$_" ne "Q"){print PP "$_\n"; push(@gpool, "$_");}}
	foreach(@ppt){if("Q$_" ne "Q"){print PT "$_\n"; push(@gpool, "$_");}}
	foreach(@tetc){if("Q$_" ne "Q"){print ETC "$_\n"; push(@gpool, "$_");}}
	print "\nwarning - not suitable to any category\n"; print "="x45,"\n";
	foreach(@rpool){
        	my $gp="$_";
        	my $m="";
        	foreach(@gpool){
                	my $rp="$_";
                	if("$rp" eq "$gp"){$m="yes"; last;}
        	}
        	if("$m" ne "yes"){print "$_\n";}
	}
	close(PP);
	close(PT);
	close(ETC);
}

sub temparray{
	@srpool = sort(@rpool);
	my %pdup=();
	@urpool = grep { ! $pdup{$_} ++ } @srpool;
	@rpool=@urpool;
}

if("$sort" eq "1"){
	opendir my $indata, $input or die "Could not open '$input' for reading '$!'\n";
	while (my $filename = readdir $indata) {
		next if (-d "$input/$filename");
		next if (! -T "$input/$filename");
		next if (! -R "$input/$filename");
		my $IF="$input/$filename";
		my $OF="$output/$filename";
		open("ifile", "$IF");
		open("OFILE", ">$OF");
		while(<ifile>){
			chomp;
			push (@rpool, "$_");
		}
		&temparray;
		foreach(@rpool){
			if("Q$_" ne "Q"){
				print OFILE "$_\n";
			}
		}
		close ("ifile");
	}
	close $indata;
	close (OFILE);
}
exit;
