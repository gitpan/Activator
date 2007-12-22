#!/usr/bin/perl -w

use Test::More tests => 1;
use Activator::Registry;
use IO::Capture::Stderr;
# bad file warns

my $capture = IO::Capture::Stderr->new();
my $line;
$capture->start();
my $badobj = Activator::Registry->new('foo');
$capture->stop();
$line = $capture->read;
ok( $line =~ /\[WARN\] 'foo' is not a valid file:/, 'bad file warns' );

