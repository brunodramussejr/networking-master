#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;
use File::Basename;
use MIME::Base64;

my $port = $ARGV[0] || 3000;
my $root = $ARGV[1] || '.';
$root =~ s|/$||;

my %mime = (
    html  => 'text/html; charset=utf-8',
    htm   => 'text/html; charset=utf-8',
    css   => 'text/css',
    js    => 'application/javascript',
    json  => 'application/json',
    png   => 'image/png',
    jpg   => 'image/jpeg',
    jpeg  => 'image/jpeg',
    gif   => 'image/gif',
    svg   => 'image/svg+xml',
    ico   => 'image/x-icon',
    woff  => 'font/woff',
    woff2 => 'font/woff2',
    ttf   => 'font/ttf',
    txt   => 'text/plain',
);

my $d = HTTP::Daemon->new(
    LocalPort => $port,
    ReuseAddr => 1,
) or die "Cannot start server on port $port: $!\n";

print "Serving '$root' at http://localhost:$port/\n";
print "Press Ctrl+C to stop.\n";

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
        my $path = $r->url->path;
        $path = '/index.html' if $path eq '/';
        $path =~ s|\.\.||g;
        my $file = $root . $path;

        if (-f $file) {
            my ($ext) = $file =~ /\.(\w+)$/;
            my $type = $mime{lc($ext // '')} || 'application/octet-stream';
            open(my $fh, '<:raw', $file) or do {
                $c->send_error(RC_INTERNAL_SERVER_ERROR);
                next;
            };
            local $/;
            my $content = <$fh>;
            close $fh;
            my $res = HTTP::Response->new(RC_OK);
            $res->header('Content-Type'   => $type);
            $res->header('Content-Length' => length($content));
            $res->content($content);
            $c->send_response($res);
        } else {
            $c->send_error(RC_NOT_FOUND, "File not found: $path");
        }
    }
    $c->close;
    undef $c;
}
