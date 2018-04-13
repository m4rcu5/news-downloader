#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
use LWP::UserAgent;

# ANWB server configuration
my @anwbServers = (
    '178.22.56.198',
    '87.233.213.245',
);

my $anwbUser = '';
my $anwbPass = '';

# helper bin
my $sox_bin = '/usr/bin/sox';

# logging
my $verbose = ($ARGV[0] && $ARGV[0] eq '-v');

# audio options
my $normLevel  = '0';
my $padSeconds = '0 1';

# storage directory
my $outbox = '/mnt/news-traffic';

# set up connection agent
my $userAgent  = LWP::UserAgent->new;
my $authString = "/distribution/get.cgi?user=${anwbUser}&pass=${anwbPass}";

# find a server that is alive
# GET /distribution/get.cgi?data=chkserver HTTP/1.1\r\n
my $originServer = undef;

foreach my $server (@anwbServers) {
    $userAgent->timeout(5);

    print "Contacting server ${server} ...", "\n" if $verbose;
    my $response = $userAgent->get('http://' . $server . $authString . '&data=chkserver');

    if ($response->is_success && $response->content eq 'OK') {
        print "Server is Alive!", "\n" if $verbose;
        $originServer = $server;
        last;
    }
}

unless (defined($originServer)) {
    die "No ANWB server is alive at this time!", "\n";
}

# fetch schedule XML
# GET /distribution/get.cgi?data=schedule&user=USERNAME&pass=PASSWORD HTTP/1.1\r\n
print "Fetching schedule ...", "\n" if $verbose;
my $schedule = $userAgent->get('http://' . $originServer . $authString . '&data=schedule');

unless ($schedule->is_success) {
    die "Could not fetch schedule data from ANWB server: ", $schedule->status_line, "\n";
}

# load schedule XML
my $document = XML::LibXML->load_xml(string => $schedule->content);

# sort bulletins by PublishTime
my @bulletins = sort {
    # Compare the DateTime strings
    $a->findvalue('./MetaData/PublishTime') cmp $b->findvalue('./MetaData/PublishTime')
} $document->findnodes('/XML/Bulletin');

# grab the latest Bulletin
my $latestBulletin = $bulletins[-1];

# some debug output
if ($verbose) {
    print "=== The following Bulletin will be downloaded ===", "\n";
    print "Bulletin Name: " . $latestBulletin->{name} . "\n";
    print "PublishDate:   " . $latestBulletin->findvalue('./MetaData/PublishTime') . "\n";
    print "Filename:      " . $latestBulletin->findvalue('./File/ServerFilename') . "\n";
    print "==================================================", "\n";
}

# fetch the latest bulletin file
# GET /distribution/get.cgi?data=file&user=USERNAME&pass=PASSWORD&value=LORANDSTADGF_alt.mp3 HTTP/1.1\r\n
print "Downloading latest bulletin file ...", "\n" if $verbose;
my $latestBulletinFile = $userAgent->get(
    'http://' . $originServer . $authString . '&data=file&value=' . $latestBulletin->findvalue('./File/ServerFilename')
);

unless ($latestBulletinFile->is_success) {
    die "Could not fetch latest bulletin: ", $latestBulletinFile->status_line, "\n";
}

# define our processing command
my $processCmd = "sox -t mp3 - " . ($verbose ? '-S -V3 ': ' ') . "${outbox}/anwbverkeer.mp3 gain -bn ${normLevel} pad ${padSeconds}";

print "Processing the bulletin...", "\n" if $verbose;

# process the audio file
open(my $processor, '|-', $processCmd) or
    die "Cannot pipe to processing command: ", $!;

print $processor $latestBulletinFile->content;

close($processor);

print "Finished processing the bulletin.", "\n" if $verbose;
