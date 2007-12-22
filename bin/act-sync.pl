#!/usr/bin/perl

use strict;
use warnings;

use Activator::Registry;
use Activator::Options;
use Activator::Log qw( :levels );
use Module::Build;
use Exception::Class::TryCatch;
use Data::Dumper;
use Template;
use File::Find;

=head1 NAME

act-sync.pl - sync developer code tree to run location

=head1 WARNING

This is a real working example of how this should work, but is not the
real implementation. It could be modified to work, but that is
painful. See TODO section in L<Activator> for more detail.

=cut

Activator::Log->level( 'INFO' );

my $opts;

# setup replacements hash
INFO("Forcing project 'rebates'");

push @ARGV, '--project=rebates';
try eval {
    $opts = Activator::Options->get_opts( \@ARGV ); 
};
if ( catch my $e ) {
    die $e;
}

my $install_base = "$ENV{HOME}/activator.run/rebates";
my $replacements = {
		    log4perl => '/etc/rebates.d/log4perl.conf',
		    install_base => "$install_base",
		    User => $ENV{USER},
                    PERL5LIB => "$install_base/lib/perl5",
		    DocumentRoot => "$install_base/var/www/rebates.com",
		    ListenPort => ( $ENV{USER} eq 'knassar' ? 11000 : 13000 ),
                    PidFile  => "$install_base/var/rebates.pid",
		    LockFile => "$install_base/var/rebates.lock",
                    cookie_domain => '.euro.rebates.com',
                    hostname      => 'euro.rebates.com',
                    host_url      => 'euro.rebates.com:'.( $ENV{USER} eq 'knassar' ? 11000 : 13000 ),
		   };

Activator::Registry->replace_in_hashref( $opts, $replacements);

if (!$opts->{src_home}) {
    Activator::Log->logdie( "You must define 'src_home' with either --src_home or env var ACT_OPT_src_home");
}

DEBUG( Dumper( $opts ) );

my $rebates_home = "$opts->{src_home}/Rebates/main";
my $activator_home = "$opts->{src_home}/Activator/main";
my $httpd_root  = $install_base . '/etc/httpd';
my $httpd_lock  = $install_base . '/var/lock';
my $httpd_run   = $install_base . '/var/run';
my $httpd_log   = $httpd_root . '/logs';
my $lib_dir     = $install_base. '/lib/perl5';
my $root_dir    = $install_base. '/var/www/rebates.com';
my $conf_dir    = $install_base. '/etc/rebates.d/';
my $rsync_debug = ( $opts->{debug} ? '-v' : '' );
foreach my $cmd (
		 "rm -rf $install_base",
		 "mkdir -p $install_base",
		 "mkdir -p $lib_dir",
		 "mkdir -p $root_dir",
		 "mkdir -p $conf_dir",
		 "mkdir -p $httpd_lock" ,
		 "mkdir -p $httpd_run" ,
		 "mkdir -p $httpd_log" ,
		 "mkdir -p $replacements->{DocumentRoot}",
		 "rsync -a $rsync_debug $activator_home/lib/* $lib_dir",
		 "rsync -a $rsync_debug $rebates_home/lib/* $lib_dir",
		 "ln -s $rebates_home/dict $conf_dir/dict",
		 "ln -s $rebates_home/root $root_dir/root",
		 "ln -sf /usr/lib/httpd/modules $httpd_root" ,
		) {
    die "$cmd failed" unless !system( $cmd );
}
find( \&process, "$activator_home/share/catalyst" );

my $reg = Activator::Registry->new();
foreach my $yml_conf ( qw( catalyst.yml registry.yml ) ) {
    $reg->register_file( "$rebates_home/conf/$yml_conf", $yml_conf );
    $reg->replace_in_realm( $yml_conf, $replacements );
    my $yml_conf_hr = $reg->get_realm( $yml_conf );
    $YAML::Syck::SingleQuote = 1;
    if ( $yml_conf eq 'registry.yml' ) {
	$yml_conf_hr = { 'Activator::Registry' => $yml_conf_hr };
    }
    YAML::Syck::DumpFile( "$conf_dir/$yml_conf", $yml_conf_hr );
}

# now we can restart
my $httpd_conf = $install_base . '/etc/httpd/conf/httpd.conf';
if ( -f $httpd_conf ) {

    INFO("calling killall httpd");
    system("killall httpd 2>/dev/null" );

    my $cmd = "/usr/sbin/apachectl -f $httpd_conf -k start";
    INFO("sleeping to allow children to exit");
    $| = 1;
    foreach ( 1..3 ) {
	print ".";
	sleep(1);
    }
    print "\n";
    INFO("starting apache");
    system( $cmd );
}
else {
    Activator::Log->logdie( "apache config not found: '$httpd_conf'");
}

sub process {
    my $dir  = $File::Find::dir; # is the current directory name,
    my $file = $_;               # is the current filename within that directory
    my $fq   = $File::Find::name; # is the complete pathname to the file.

    $fq =~ m|share/catalyst/(.+)\.tt$|;
    my $out = $1;
    return unless $out;

    DEBUG( qq( processing $file into $install_base/$out ) );
    my $tt = Template->new( { DEBUG => 1,
			      ABSOLUTE => 1,
			      OUTPUT_PATH  => $install_base,
			    }
			  );
    $tt->process( $fq, $opts, $out ) || Activator::Log->logdie( $tt->error()."\n");
    if( $out =~ m@/s?bin/|/init.d/@ ) {
	chmod 0755, "$install_base/$out";
    }
}
