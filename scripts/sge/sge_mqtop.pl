#!/usr/local/bin/perl

use IO::Socket;
my $sock = new IO::Socket::INET->new (
                                  PeerAddr => "$ARGV[0]",
                                  PeerPort => '14235',
                                  Proto    => 'tcp',
                                  Timeout  => '10',
                                );

die "Couldn't connect to host!\n" unless $sock;
$msg="$ARGV[1]\n";
if (!$sock->send($msg))
{
    exit 1;
}
$msg="$ARGV[2]:$ARGV[3]\n";
if (!$sock->send($msg))
{
    exit 1;
}
while (<$sock>) { print }
close ($sock);

