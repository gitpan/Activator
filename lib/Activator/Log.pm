package Activator::Log;

require Exporter;
push @ISA, qw( Exporter );
@EXPORT_OK = qw( FATAL ERROR WARN INFO DEBUG TRACE );
%EXPORT_TAGS = ( levels => [ qw( FATAL ERROR WARN INFO DEBUG TRACE ) ] );

use Log::Log4perl;
use Scalar::Util;
use Data::Dumper;
use Activator::Registry;
use base 'Class::StrongSingleton';

=head1 NAME

Activator::Log - provide a simple wrapper for L<Log::Log4perl> for use
within an Activator project.

=head1 SYNOPSIS

  use Activator::Log;
  Activator::Log::WARN( $msg );

  use Activator::Log qw( :levels );
  WARN( $msg );

  #### Alternate log levels
  Activator::Log->level( $level );

=head1 DESCRIPTION

This module provides a simple wrapper for L<Log::Log4perl> that allows
you to have a project level configuration for Log4perl, and have any
class or script in your project be configured and output log messages
in a consistent centralized way.

Additionally, C<TRACE> and C<DEBUG> functions have the extra
capabilities to turn logging on and off on a per-module basis. See the
section L<DISABLING DEBUG OR TRACE BY MODULE> for more information.

=head2 Centralized Configuration

Your project C<log4perl.conf> gets loaded based on your
L<Activator::Registry> configuration. If you do not have a Log4perl
config available, the log level is set to WARN and all output goes to
STDERR.

See the section L<CONFIGURATION> for more details.

=head2 Exporting Level Functions

Log::Log4perl logging functions are exported into the global
namespace if you use the C<:levels> tag

    use Activator::Log qw( :levels );
    &FATAL( $msg );
    &ERROR( $msg );
    &WARN( $msg );
    &INFO( $msg );
    &DEBUG( $msg );
    &TRACE( $msg );

=head2 Static Usage

You can always make static calls to this class no matter how you 'use'
this module:

  Activator::Log->FATAL( $msg );
  Activator::Log->ERROR( $msg );
  Activator::Log->WARN( $msg );
  Activator::Log->INFO( $msg );
  Activator::Log->DEBUG( $msg );
  Activator::Log->TRACE( $msg );


=head2 Additional Functionality provided

The following Log::Log4perl subs you would normally call with
$logger->SUB are supported through a static call:

  Activator::Log->logwarn( $msg );
  Activator::Log->logdie( $msg );
  Activator::Log->error_warn( $msg );
  Activator::Log->error_die( $msg );
  Activator::Log->logcarp( $msg );
  Activator::Log->logcluck( $msg );
  Activator::Log->logcroak( $msg );
  Activator::Log->logconfess( $msg );
  Activator::Log->is_trace()
  Activator::Log->is_debug()
  Activator::Log->is_info()
  Activator::Log->is_warn()
  Activator::Log->is_error()
  Activator::Log->is_fatal()

See the L<Log::Log4perl> documentation for more details.

=head1 CONFIGURATION

=head2 Log::Log4perl

Activator::Log looks in your Registry for a L<Log::Log4perl>
configuration in this heirarchy:

1) A 'log4perl.conf' file in the registry:

 'Activator::Registry':
    log4perl.conf: <file>

2) A 'log4perl' config in the registry:

 'Activator::Registry':
    log4perl:
      'log4perl.key1': 'value1'
      'log4perl.key2': 'value2'
      ... etc.

3) If none of the above are set, C<Activator::Log> defaults to
C<STDERR> exactly as shown below.

Note that even if C<log4perl.conf> or C<log4perl> is set,
L<Log::Log4perl> by default doesn't log anything. You must properly
configure it for this module. As an example, the (hash format)
configuration used by this module for logging to STDERR (#4 above) is:

  'log4perl.logger.Activator.DB' => 'WARN, Screen',
  'log4perl.appender.Screen' => 'Log::Log4perl::Appender::Screen',
  'log4perl.appender.Screen.layout' => 'Log::Log4perl::Layout::PatternLayout',
  'log4perl.appender.Screen.layout.ConversionPattern' => '%d{yyyy-mm-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n',

Consult with L<Log::Log4perl> documentation for more information on
how to create the C<log4pler.conf> file, or the C<log4perl> registry
entry.

=head2 Setting the Default Log Level

Set up your registry as such:

 'Activator::Registry':
   'Activator::Log':
     default_level: LEVEL

Note that you can also initialize an instance of this module with the
same affect:

  Activator::Log->new( $level );

=head1 DISABLING DEBUG OR TRACE BY MODULE

By default, this module will print all C<DEBUG> and C<TRACE> log messages
provided that the current log level is high enough. However, when
developing it is convenient to be able to turn debugging/tracing on
and off on a per-module basis. The following examples show how to do
this.

=head2 Turn debugging OFF on a per-module basis

 'Activator::Registry':
    'Activator::Log':
      DEBUG:
        'My::Module': 0    # My::Module will now prove "silence is bliss"

=head2 Turn debugging ON on a per-module basis

 'Activator::Registry':
    'Activator::Log':
      DEBUG:
        FORCE_EXPLICIT: 1
        'My::Module': 1    # only My::Module messages will be debugged
      TRACE:
        FORCE_EXPLICIT: 1
        'Other::Module': 1 # only Other::Module messages will be traced

=head2 Disabling Caveats

Note that the entire Activator framework uses this module, so use
FORCE_EXPLICIT with caution, as you may inadvertantly disable logging
from a package you DO want to hear from.

=head1 USING THIS MODULE IN WRAPPERS

This module respects C<$Log::Log4perl::caller_depth>. When using this
module from a wrapper, please consult with Log4perl "Using
Log::Log4perl from wrapper classes" in the Log4perl FAQ.

=cut

# constructor: implements singleton
sub new {
    my ( $pkg, $level ) = @_;

    my $self = bless( { }, $pkg);

    $self->_init_StrongSingleton();

    if ( Log::Log4perl->initialized() ) {
	# do nothing, logger already set
    }
    else {
	my $config = Activator::Registry->get('Activator::Log');
	$self->{DEFAULT_LEVEL} =
	  $level ||
	    $config->{default_level} ||
	      'WARN';

	$l4p_config = Activator::Registry->get('log4perl.conf') ||
	  Activator::Registry->get('log4perl') ||
	      { 'log4perl.logger.Activator.Log' => "$self->{DEFAULT_LEVEL}, Screen",
		'log4perl.appender.Screen' => 'Log::Log4perl::Appender::Screen',
		'log4perl.appender.Screen.layout' => 'Log::Log4perl::Layout::PatternLayout',
		'log4perl.appender.Screen.layout.ConversionPattern' => '%d{yyyy-mm-dd HH:mm:ss.SSS} [%p] %m (%M %L)%n',
	      };
	Log::Log4perl->init_once( $l4p_config );
	$Log::Log4perl::caller_depth++;
	$self->{LOGGER} = Log::Log4perl->get_logger();
    }

    return $self;
}

sub level {
    my ( $pkg, $level ) = @_;
    my $self = &new( 'Activator::Log' );
    if ( !$pkg ) {
	Activator::Exception::Log->throw( 'level', 'required_argument');
    }
    if ( !$pkg->isa( 'Activator::Log' ) ) {
	$level = $pkg;
    }
    $self->{LOGGER}->level( $level );
}

sub FATAL {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->fatal( $msg );
}

sub ERROR {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->error( $msg );
}

sub WARN {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->warn( $msg );
}

sub INFO {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->info( $msg );
}

sub DEBUG {
    my ( $pkg, $msg ) = @_;
    my $caller = caller;
    my $self = &new( 'Activator::Log' );
    my $debug = &_enabled( 'DEBUG', $caller );
    if ( $debug ) {
	$msg = _get_msg( $pkg, $msg );
	$self->{LOGGER}->debug( $msg );
    }

}

sub TRACE {
    my ( $pkg, $msg ) = @_;
    my $caller = caller;
    my $self = &new( 'Activator::Log' );
    my $trace = &_enabled( 'TRACE', $caller );
    if ( $trace ) {
	$msg = _get_msg( $pkg, $msg );
	$self->{LOGGER}->trace( $msg );
    }
}

sub is_fatal {
    my $self = &new( 'Activator::Log' );
    return $self->{LOGGER}->is_fatal();
}

sub is_error {
    my $self = &new( 'Activator::Log' );
    return $self->{LOGGER}->is_error();
}

sub is_warn {
    my $self = &new( 'Activator::Log' );
    return $self->{LOGGER}->is_warn();
}

sub is_info {
    my $self = &new( 'Activator::Log' );
    return $self->{LOGGER}->is_info();
}

sub is_debug {
    my $self = &new( 'Activator::Log' );
    return $self->{LOGGER}->is_debug();
}

sub is_trace {
    my $self = &new( 'Activator::Log' );
    return $self->{LOGGER}->is_trace();
}

sub logwarn {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->logwarn( $msg );
}

sub logdie {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->logdie( $msg );
}

sub error_warn {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->error_warn( $msg );
}

sub error_die {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->error_die( $msg );
}

sub logcarp {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );B
    $self->{LOGGER}->logcarp( $msg );
}

sub logcluck {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->logcluck( $msg );
}

sub logcroak {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->logcroak( $msg );
}

sub logconfess {
    my ( $pkg, $msg ) = @_;
    my $self = &new( 'Activator::Log' );
    $msg = _get_msg( $pkg, $msg );
    $self->{LOGGER}->logconfess( $msg );
}


sub _enabled {
    my ( $level, $pkg ) = @_;

    return 1 if !$pkg;

    my $log_config = Activator::Registry->get('Activator::Log');
    my $config = $log_config->{$level};

    my $pkg_setting = -1;
    if (exists( $config->{$pkg} ) &&
	defined( $config->{$pkg} ) ) {
	$pkg_setting = $config->{$pkg};
    }
    my $force_explicit = -1;
    if (exists( $config->{FORCE_EXPLICIT} ) &&
	defined( $config->{FORCE_EXPLICIT} ) ) {
	$force_explicit = $config->{FORCE_EXPLICIT};
    }

    return
      ( $force_explicit == 1 && $pkg_setting == 1 ) ||
	( $force_explicit < 1 && $pkg_setting != 0 ) ||
	  0;
}

# helper to handle static and OO calls
sub _get_msg {
    my ( $pkg, $msg ) = @_;

    if ( !$pkg && !$msg ) {
	$msg = '<empty message>';
    }
    elsif ( !$msg ) {
	if ( UNIVERSAL::isa( $pkg, 'Activator::Log' ) ) {
	    $msg = '<empty message>';
	}
	else {
	    $msg = $pkg;
	}
    }
    chomp $msg;
    return $msg;
}

