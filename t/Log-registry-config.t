#!perl
use warnings;
use strict;

use Activator::Log;
use Activator::Registry;
use IO::Capture::Stderr;
use Test::More tests => 9;

my $logfile = "/tmp/activator-log-test.log";
my $config  =  {
		'log4perl.logger.Activator.Log' => 'WARN, LOGFILE',
		'log4perl.appender.LOGFILE' => 'Log::Log4perl::Appender::File',
		'log4perl.appender.LOGFILE.filename' => '/tmp/activator-log-test.log',
		'log4perl.appender.LOGFILE.mode' => 'append',
		'log4perl.appender.LOGFILE.layout' => 'PatternLayout',
		'log4perl.appender.LOGFILE.layout.ConversionPattern' => '%d{yyyy-mm-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n,',

	       };
Activator::Registry->register('log4perl', $config );

# tests for all functions
Activator::Log::level( 'TRACE' );
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

# test log levels
Activator::Log::level( 'FATAL' );
Activator::Log::TRACE('TRACE');
Activator::Log::DEBUG('DEBUG');
Activator::Log::INFO('INFO');
Activator::Log::WARN('WARN');
Activator::Log::ERROR('ERROR');
Activator::Log::FATAL('FATAL');

my $line;
my $cmd_failed = !open LOG, "<$logfile";
ok( !$cmd_failed, "can open log file" );

foreach my $msg ( qw/ TRACE DEBUG INFO WARN ERROR FATAL / ) {
    $line = <LOG>;
    ok ( $line =~ /\[$msg\] $msg \(main::/, "$msg logged" );
}

$line = <LOG>;
ok( $line =~ /\[FATAL\] FATAL \(main::/, "Changing log level works" );

$cmd_failed = system ( "rm -f $logfile" );
ok( !$cmd_failed, "rm logfile $logfile" );
