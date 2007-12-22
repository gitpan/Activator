#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

plan skip_all => 'set TEST_ACT_EMAILER to enable this test' unless $ENV{TEST_ACT_EMAILER};

# DEFINE THIS TO TEST
my $to = '';

BEGIN {
    $ENV{ACT_REG_YAML_FILE} = "$ENV{PWD}/t/data/Emailer/registry.yml";
}

use Activator::Emailer;
use Activator::Log;
Activator::Log->level('DEBUG');

my $tt_vars = { name => 'Karim Nassar' };
my $mailer = Activator::Emailer->new(
				     To          => $to,
				     Subject     => 'Final Test? ',
				     html_body   => 'html_body.tt',
				     tt_options  => { INCLUDE_PATH => "$ENV{PWD}/t/data/Emailer" },
				    );

# future test
#$mailer->attach(
#		Type        => 'application/msword',
#		Path        => '/home/knassar/rebates.com_mission.doc',
#		Filename    => 'mission.doc',
#		Disposition => 'attachment' );

print Dumper( $mailer)."\n";

lives_ok {
    $mailer->send( $tt_vars );
} 'can send email';
