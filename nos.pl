#!/usr/bin/perl
use strict;
use warnings;

use LWP::UserAgent;

# NOS server configuration
my $NOSBaseUrl = 'http://download.nos.nl/';

my $NOSUser = '';
my $NOSPass = '';

# NOS download URLs
my %downloadUrls = (
    'nosnieuws.mp3'     => 'radiojournaal/nosnieuws.mp3',
    'nosheadlines.mp3'  => 'radiojournaal/nosheadlines.mp3',
    'nieuwsminuut.mpeg' => 'nieuwsminuut/nieuwsminuut.mpeg',
);

# helper bin
my $sox_bin = '/usr/bin/sox';

# logging
my $verbose = ($ARGV[1] && $ARGV[1] eq '-v');

# audio options
my $normLevel  = '0';
my $padSeconds = '0 1';

# storage directory
my $outbox = '/mnt/news-traffic';

# identify requested file
unless ($ARGV[0] && defined $downloadUrls{$ARGV[0]}) {
    die "Invalid download requested!", "\n";
}

my $requestFile = $ARGV[0];

my $isAudio = ($requestFile =~ m/\.mp3$/x);

my $requestUrl = $NOSBaseUrl . $downloadUrls{$requestFile};

# set up connection agent
my $userAgent   = LWP::UserAgent->new;
my $httpRequest = HTTP::Request->new(GET => $requestUrl );

$httpRequest->authorization_basic( $NOSUser, $NOSPass );

print "Downloading ${requestUrl} ...", "\n" if $verbose;

my $latestBulletinFile = $userAgent->request( $httpRequest );

unless ($latestBulletinFile->is_success) {
    die "Could not fetch latest bulletin: ", $latestBulletinFile->status_line, "\n";
}

if ($isAudio) {
    # if it is audio we need some processing

    # define our processing command
    my $processCmd = "sox -t mp3 - " . ($verbose ? '-S -V3 ': ' ') . "${outbox}/${requestFile} gain -bn ${normLevel} pad ${padSeconds}";

    print "Processing the bulletin...", "\n" if $verbose;

    # process the audio file
    open(my $processor, '|-', $processCmd) or
        die "Cannot pipe to processing command: ", $!;

    print $processor $latestBulletinFile->content;

    close($processor);

    print "Finished processing the bulletin.", "\n" if $verbose;
} else {
    # if not, we just write the file

    open(my $fh, ">", $outbox . '/' . $requestFile) or
        die "Cannot open output file", $!;

    print $fh $latestBulletinFile->content;

    close($fh);

    print "Wrote latest bulletin file.", "\n" if $verbose;
}
