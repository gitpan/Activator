package Activator::Build;
use strict;
use warnings;

use base 'App::Build';

1;

__END__

=head1 NAME 

Activator::Build - subclass to Module::Build for creating cpan modules.

=head1 TODO

Implement! Current is just a stub subclass of L<App::Build>, with
example code for subclassing plans for L<Module::Build>.

=cut

# TODO: the real way to subclass module::build
use Module::Build;
use Activator::Log qw( :levels );
use Data::Dumper;

our @ISA = ("Module::Build");

sub new {
    my ( $pkg, %build_opts ) = @_;
    my $self = $pkg->SUPER::new( module_name => 'Activator::Build', %build_opts );
    return $self;
}

sub ACTION_install {
    my $self = shift;

    # install perl modules
    $self->SUPER::ACTION_install;


}

