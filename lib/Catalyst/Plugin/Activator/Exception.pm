package Catalyst::Plugin::Activator::Exception;

use strict;
use warnings;
use Activator::Log qw( :levels );
use Activator::Exception;
use Symbol;

*{Symbol::qualify_to_ref('throw', 'Catalyst')} = sub {

    return &Catalyst::Plugin::Activator::Exception::throw( @_ );
};

sub throw {
    my ($c, $e) = @_;

    if ( !defined $e ) {
	$e = new Activator::Exception('unknown');
    }

    if ( $e eq '' ) {
	$e = new Activator::Exception('unknown');
    }

    if ( !$c->stash->{e}) {
	$c->stash->{e} = ();
    }

    if ( UNIVERSAL::isa( $e, 'Exception::Class' ) ) {
	push @{ $c->stash->{e} }, $e;
    }
    else {
	push @{ $c->stash->{e} }, Activator::Exception->new( $e );
    }
    return;
}

sub finalize {
    my ($c) = @_;
    delete $c->stash->{e};
    return $c->NEXT::finalize(@_);
}
