package Activator::Registry;
use YAML::Syck;
use base 'Class::StrongSingleton';
use Activator::Log qw( :levels );
use Data::Dumper;
use Hash::Merge;
use Activator::Exception;
use Exception::Class::TryCatch;

=head1 NAME

Activator::Registry - provide a registry based on YAML file(s)

=head1 SYNOPSIS


  use Activator::Registry;

  #### register $value to $key in realm $realm
  Activator::Registry->register( $key, $value, $realm );

  #### register $value to $key in default realm
  Activator::Registry->register( $key, $value );

  #### get value for $key from $realm
  Activator::Registry->get( $key, $realm );

  #### get value for $key from default realm
  Activator::Registry->get( $key );

  #### register YAML file into realm
  Activator::Registry->register_file( $file, $realm );

  #### register hash into realm
  Activator::Registry->register_hash( $mode, $hashref, $realm );

=head1 DESCRIPTION

This module provides global access to a registry of key-value pairs.
It is implemented as a singleton, so you can use this Object Oriented
or staticly with arrow notation. It supports setting of deeply nested
objects. (See L<FUTURE WORK> for plans for deep C<get>ting.)

=head1 CONFIGURATION

This module expects (but does not require) an environment variable
ACT_REG_YAML_FILE to be set. When set, this file is automatically
loaded upon the first call to C<new()>.

If you are utilizing this module from apache, this directive must be
in your httpd configuration:

  SetEnv ACT_REG_YAML_FILE '/path/to/config.yml'

If you are using this module from a script, you need to insure that
the environment is properly set using a BEGIN block BEFORE the C<use>
statement of any module that C<use>s C<Activator::Registry> itself:

  BEGIN{
      $ENV{ACT_REG_YAML_FILE} ||= '/path/to/reg.yml'
  }

Otherwise, you will get weirdness when all of your expected registry
keys are undef...

=head1 METHODS

=head2 new ( $yaml )

=over

Create a new registry object. This is a singleton, so repeated calls
always return the same ref. Optionally takes C<$yaml> as an argument
and will register that file.

=back

=cut

sub new {
    my ( $pkg, $yaml ) = @_;

    my $self = bless( {
          DEFAULT_REALM => 'default',
          REGISTRY => {},

# TODO: consider using custom precedence
#          SAFE_LEFT_PRECEDENCE =>
#           {
#            'SCALAR' => {
#               'SCALAR' => sub { $_[0] },
#               'ARRAY'  => &die_array_scalar,
#               'HASH'   => &die_hash_scalar,
#              },
#            'ARRAY' => {
#               'SCALAR' => sub { [ @{ $_[0] }, $_[1] ] },
#               'ARRAY'  => sub { [ @{ $_[0] }, @{ $_[1] } ] },
#               'HASH'   => &die_hash_array,
#              },
#            'HASH' => {
#               'SCALAR' => &die_scalar_hash,
#               'ARRAY'  => &die_array_hash,
#               'HASH'   => sub { _merge_hashes( $_[0], $_[1] ) },
#              },
#	  },

		      }, $pkg);

    $self->_init_StrongSingleton();

    $yaml ||= $ENV{ACT_REG_YAML_FILE};

    if ( defined( $yaml ) ) {
	if ( !keys( %{ $self->{REGISTRY} } )
	     #|| $self->get( 'ACTIVATOR_REGISTRY_FORCE_RELOAD' )
	   ) {
	    if ( -f $yaml ) {
		$self->register_file( $yaml );
	    } else {
		WARN( "'$yaml' is not a valid file: registry not loaded");
		return $self;
	    }
	}
    }
    return $self;
}

=head2 register( $key, $value, $realm )

=over

Register a key-value pair to C<$realm>. Registers to the default realm
if C<$realm> not defined. Returns true on success, false otherwise
(more specifically, the return value of the C<eq> operator).

=back

=cut

sub register {
  my ($pkg, $key, $value, $realm) = @_;
  my $self = $pkg->new();
  $realm ||= $self->{DEFAULT_REALM};
  $self->{REGISTRY}->{ $realm }->{ $key } = $value;
  return $self->{REGISTRY}->{ $realm }->{ $key } eq $value;
}

=head2 register_file( $file, $realm)

=over

Register the contents of the C<'Activator::Registry':> heirarchy from
within a YAML file, then merge it into the existing registry for the
default realm, or optionally C<$realm>.

=back

=cut

sub register_file {
    my ( $pkg, $file, $realm ) = @_;
    my $self = $pkg->new();
    $realm ||= $reg->{DEFAULT_REALM};
    my $config = YAML::Syck::LoadFile( $file );
    $self->register_hash( 'left', $config->{'Activator::Registry'}, $realm );
}


=head2 register_hash( $mode, $right, $realm)

=over

Set registry keys in C<$realm> from C<$right> hash using C<$mode>,
which can either be C<left> or C<right>. C<left> will only set keys
that do not exist, and C<right> will set or override all C<$right>
values into C<$realm>'s registry.

=back

=cut

sub register_hash {
    my ( $pkg, $mode, $right, $realm ) = @_;
    if ( $mode eq 'left' ) {
	Hash::Merge::set_behavior( 'LEFT_PRECEDENT' );
    }
    elsif ( $mode eq 'right' ) {
	Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
    }
    else {
	# TODO: consider using custom precedence
	#Hash::Merge::specify_behavior( $pkg->{SAFE_LEFT_PRECEDENCE} );

	Activator::Exception::Registry->throw( 'mode', 'invalid' );
    }
    my $reg = $pkg->new();
    $realm ||= $reg->{DEFAULT_REALM};
    if ( !exists( $reg->{REGISTRY}->{ $realm } ) ) {
	$reg->{REGISTRY}->{ $realm } = {};
    }
    my $merged = {};
    try eval {
	$merged = Hash::Merge::merge( $reg->{REGISTRY}->{ $realm }, $right );
    };
    # catch
    if ( catch my $e ) {
	Activator::Exception::Registry->throw( 'merge', 'failure', $e );
    }

    elsif( keys %$merged ) {
	$reg->{REGISTRY}->{ $realm } = $merged;
    }
}

=head2 get( $key, $realm )

=over

Get the value for C<$key> within C<$realm>. If C<$realm> not defined
returns the value from the default realm.

=back

=cut

sub get {
   my ($pkg, $key, $realm) = @_;

   my $self = $pkg->new();
   $realm ||= $self->{DEFAULT_REALM};
   return $self->{REGISTRY}->{ $realm }->{ $key };
}

=head2 get_realm( $realm )

=over

Return a reference to hashref for an entire C<$realm>.

=back

=cut

sub get_realm {
   my ($pkg, $realm) = @_;

   my $self = $pkg->new();
   $realm ||= $self->{DEFAULT_REALM};
   return $self->{REGISTRY}->{ $realm };
}


=head2 merge_hashes( $left_hr, $right_hr, $precedence )


=over

THIS DOES NOT WOIK.

Merge two hashes together, return a reference to the new hash.

When precedence is C<left>(default), new keys are added from C<$right_hr>. When precedence is C<right> new keys are added from C<$left_hr>.

Precedent side's values never get stomped.

See L<Hash::Merge> for more information on merge methodology. This
method uses the C<LEFT_PRECEDENCE> and C<RIGHT_PRECEDENCE>.

=back

=cut

sub merge_hashes {
    my ( $self, $lefthash, $righthash, $precedence ) = @_;

    # safety check inputs
    if ( !UNIVERSAL::isa( $lefthash, 'HASH' ) ) {
	DEBUG( "LEFT is not a hashref: " . Dumper( $lefthash ) );
	Activator::Exception::Registry->throw( 'left', 'not_a_hashref' );
    }

    if ( !UNIVERSAL::isa( $righthash, 'HASH' ) ) {
	DEBUG( "RIGHT is not a hashref: " . Dumper( $righthash ) );
	Activator::Exception::Registry->throw( 'right', 'not_a_hashref' );
    }

    if ( $precedence ne 'right' and $precedence ne 'left' ) {
	Activator::Exception::Registry->throw( 'precedence', 'invalid', $precedence );
    }

    my ( $left, $right );
    if ( $precedence eq 'left' ) {
	$left = $lefthash;
	$right = $righthash;
    }
    elsif ( $precedence eq 'right' ) {
	$right = $lefthash;
	$left = $righthash;
    }

    # process the right hash
    foreach my $rightkey ( keys %$right ) {

	# copy/merge right to left if left does not exist
	if ( !exists $left->{ $rightkey } ) {

	    # if right is a hash, recurse
	    if ( UNIVERSAL::isa( $right->{ $rightkey }, 'HASH')) {
		# set left ref to an anonymous hashref of the deeply merged hashes
		$left->{ $rightkey } = &merge_hashes ( {}, $right->{ $rightkey } );
		return if !$left->{ $rightkey };
	    }

	    # not a hash. just copy
	    else {
		$left->{ $rightkey } = $right->{ $rightkey };
	    }
	}

	# merge right to left if left is a hash
	elsif ( UNIVERSAL::isa( $left->{ $rightkey }, 'HASH')) {
	    $left->{ $rightkey } = &merge_hashes ( $left->{ $rightkey }, $right->{ $rightkey } );
	    return if !$left->{ $rightkey };
	}
    }

    return $left;
}

=head2 replace_in_realm( $replacements, $realm )

=over

Replace variables matching C<${}> notation with the values in
C<$replacements>. Optionally, do it only for C<$realm>. If C<$realm>
is not specified, acts on only the C<default> realm.

=back

=cut

sub replace_in_realm {
    my ($pkg, $realm, $replacements) = @_;
    my $self = $pkg->new();

    my $reg = $self->get_realm( $realm );
    if ( !keys %$reg ) {
	Activator::Exception::Registry->throw( 'realm', 'invalid', $precedence );
    }

    DEBUG("replacing (realm '$realm') ". Dumper($reg) . "\n ---- with ----\n". Dumper($replacements));
    $self->replace_in_hashref( $reg, $replacements );
    DEBUG("Done replacing. End result: ". Dumper($reg));
}

=head2 replace_in_hashref( $hashref, $replacements )

=over

Replace withing the values of C<$hashref> keys, variables matching
C<${}> notation with the values in C<$replacements>.

=back

=cut

sub replace_in_hashref {
    my ( $pkg, $hashref, $replacements ) = @_;

    foreach my $key ( keys %$hashref ) {

	# if key is a hash, recurse
	if ( UNIVERSAL::isa( $hashref->{ $key }, 'HASH')) {
	    $pkg->replace_in_hashref( $hashref->{ $key }, $replacements );
	}

	# if key is an array, do replacements for each item
	elsif ( UNIVERSAL::isa( $hashref->{ $key }, 'ARRAY')) {
	    for( my $i = 0; $i < @{ $hashref->{ $key } }; $i++ ) {
		my $elem = @{ $hashref->{ $key }}[ $i ];
		@{ $hashref->{ $key }}[ $i ] = $pkg->get_replaced_string( $elem, $replacements );
	    }
	}

	# if key is a string just do the replacment for the string
	else {
	    $hashref->{ $key } = $pkg->get_replaced_string( $hashref->{ $key }, $replacements );
	}

    }
}

=head2 get_replaced_string( $target, $replacements )

=over

Return the value of C<$target> after replacing variables matching
C<${}> notation with the values in C<$replacements>.

=back

=cut

sub get_replaced_string {
    my ( $pkg, $target, $replacements ) = @_;

    my @matches = ( $target =~ /\$\{([^\}]+)/g );
    if ( @matches ) {
	DEBUG( "found variables: (".join (',',@matches) . ") in target '$target'");
	map {
	    my $replace = $replacements->{ $_ };
	    if ( defined $replace ) {
		$target =~ s/\$\{$_\}/$replace/g;
		DEBUG("Replaced '\${$_}' with '$replace'. target is '$target'");
	    } else {
		DEBUG("Skipped variable '$_'. Does not have a replacement value.");
	    }
	} @matches;
    }
    else {
	DEBUG( "No variables to replace in '$target'");
    }
    return $target;
}


# register_hash helpers for when using SAFE_LEFT_PRECEDENCE merging
# not currently used
sub die_array_scalar {

    die "Can't coerce ARRAY into SCALAR\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( ARRAY SCALAR ) ] );
}

sub die_hash_scalar {
    die "Can't coerce HASH into SCALAR\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( HASH SCALAR ) ] );
}

sub die_hash_array {
    die "Can't coerce HASH into ARRAY\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( HASH ARRAY ) ] );
}

sub die_scalar_hash {
    die "Can't coerce SCALAR into HASH\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( SCALAR HASH ) ] );
}

sub die_array_hash {
    die "Can't coerce ARRAY into HASH\n" .
      Data::Dumper->Dump( [ $_[0], $_[1] ],
			  [ qw( ARRAY HASH ) ] );
}



=head1 FUTURE WORK

=over

=item * Deep C<get>ting

At this time, you cannot C<get> from deep within the heirarchy:
you must get the top level key then fetch it yourself. In the future
we will support arrow notation:

  Activator::Registry->get('top->deep->deeper');

=item * Dynamic Reloading

It'd probably be nice to be able to force reload so you could edit
your registry file programatically.

=item * Hash merging doesn't belong here

In the future, merge_* methods will be removed.

=item * Utilize other merge methods

Only the default merge mechanism for L<Hash::Merge> is used. It'd be
more robust to support other mechanisms as well.

=back

=head1 See Also

L<Activator::Log>, L<Activator::Exception>, L<YAML::Syck>,
L<Exception::Class::TryCatch>, L<Class::StrongSingleton>

=head1 AUTHOR

Karim Nassar ( karim.nassar@acm.org )

=head1 License

The Activator::Registry module is Copyright (c) 2007 Karim Nassar.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, or as specified in the Perl README file.

=cut


1;
