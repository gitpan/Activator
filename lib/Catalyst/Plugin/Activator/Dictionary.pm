package Catalyst::Plugin::Activator::Dictionary;
use strict;
use warnings;
use Activator::Dictionary;


=head1 NAME

Catalyst::Plugin::Activator::Dictionary : Provide a Catalyst context
L<Activator::Dictionary> C<lookup()> function, and template lookup magic.

=head1 SYNOPSIS

  # in MyApp.pm
  use Catalyst qw/ Activator::Plugin /;

  # Later, in some Controller
  $c->lookup('dict_key');

=head1 DESCRIPTION

This Catalyst plugin provides the two features listed in the L<METHODS> section.

=head1 METHODS

=head2 lookup

Provides a wrapper to L<Activator::Dictionary> lookup function usable
wherever you have access to the catalyst context object C<$c>.

  # lookup in C<web> realm
  $c->lookup('dict_key');

  # lookup in alternate realm
  $c->lookup('dict_key', 'other_realm');

=cut

sub lookup {
    my ( $c, $key, $realm ) = @_;
    $realm ||= 'web';
    my $dict = Activator::Dictionary->get_dict( $c->stash->{dict_lang} );
    return $dict->lookup( $key, $realm );
};


=head2 finalize

Does a regular expression replacement of C<%{}> formatted keys into
dictionary lookups from the C<web> realm.

Example:

In C</path/to/dictionary/en/web.dict>:

  nice_para  This is a nice paragraph.

In a template:

  <p>%{nice_para}</p>

Resulting HTML:

<p>This is a nice paragraph.</p>

=cut

sub finalize {
    my ($c) = @_;

    ## we have html output
    if( $c->res->status == 200 && $c->res->content_type =~ 'text/html' ) {
	my $dict = Activator::Dictionary->get_dict( $c->stash->{dict_lang} );
	my $body = $c->res->body();
	$body =~ s/\%\{([^\}]+)\}/$dict->lookup( $1, 'web' )/egi;
	$c->res->body( $body );
    }

    return $c->NEXT::finalize(@_);
}

=head1 SEE ALSO

L<Activator::Dictionary>, L<Catalyst>, L<Catalyst::Manual::Plugins>


=head1 AUTHOR

Karim Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License, or the Artistic License as specified in the Perl
README file.

=cut

1;
