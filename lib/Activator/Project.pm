package Activator::Project;
use strict;
use warnings;
use Activator::Log;
use File::Rsync;

=head1 NAME

Activator::Project

=head1 DESCRIPTION

THIS IS A TODO DESCRIPTION. ANY CODE IMPLEMENTED IS ONLY TO LAY DOWN IDEAS.

Control the building and installation of an Activator project. Can
sync a development codebase for local or remote instances, build
packages for distribution, or install packages based on your Activator
project configuration. This modules supports build types:

=over

=item * sync

sync the codebase to the local or a remote server.

=item * cpan

create a cpan distributable tarball for the project

=item * tgz

create a plain tarball of the project

=item * rpm

create a rpm of the project

=item * deb

create a deb of the project

=back

=head1 CONFIGURATION

C<Activator::Builder> utilizes L<Activator::Registry> for
configuration, and the provided builder script grabs these options
using L<Activator::Options>.

Create a project configuration directory C<activator.d> in the top
level of your project code directory. Then, create a project YAML
configuration file C<E<lt>projectE<gt>.yml> using these project
configuration options:

support this project.yml config:

  <realm>:   you can create any number of realms. This option allows
             mutliple definitions of behavior
    build:
      type:  one of sync, cpan, tgz rpm, deb
      dest:
    install:
      type:  one of sync, cpan, tgz rpm, deb
      dest: /path/to/install/base
      user: user to login as
      host: hostname or ip to install to

    packages:
      <package>:
        root: # where the code lives

        # requirements
        build_requires:
        install_requires:
          <type>:  one of sync, cpan, tgz rpm, deb
            <module or package>: <version>

        # these files/dirs copied (recursively) unless listed in 'symlink' section
        include:
          <local dir>: <dest dir>
          <local file>: <dest file>

        # these files are processed via Template Toolkit
        process:
          <local dir>: <dest dir>
          <local file>: <dest file>

        # absolute paths supported, relative must be in the package root
        # when dest is remote, these still get created
        # side affect: $() notation will work when run in bash shells
        symlink:
          <local dir>: <local dir>
          <local file>: <local file>

        services:
          - list of service aliases: any extra processing that a
            service might require is done during 'build', and services
            are restarted during 'install'.

    services: services that are expected to conform with redhat
              style service command ( start|stop|restart|reload ).
      <service alias>:
        init_script: <etc/init.d script location>
        priority:  <priority>
        build: extra processing for 'build' command.
        install: extra processing for 'install' command.
                 These two sections follow the same format for
                 'include','process','symlink' sections in the
                 'packages' section above. For example:
          process:
            /path/to/files: /path/to/output

=cut

sub new {

    my ( $pkg, $opts) = @_;
    my $self = bless( { OPTS => $opts }, $pkg );
    return $self;
}


=head2 build

Creates a build directory with contents consisting of the results of
processing the C<include>, C<process>, C<symlink> and C<services>
sections, plus a C<PACKAGES> directory if the
C<E<lt>realm>E<gt>-E<gt>build>-E<gt>type is one of C<cpan>, C<tgz>,
C<rpm>, or C<deb>.

=cut

sub build {
    my ( $self ) = @_;

    # convenience vars
    my $opts = $self->{OPTS};
    my $build_base = $opts->{build}->{dest} ||
      Activator::Exception::Project->throw( 'build_base_missing' );
    my $realm = $self->{OPTS}->{realm} ||
      Activator::Exception::Project->throw( 'realm_missing' );

    # process all packages, plus any service extras
    foreach my $section ( qw( packages services ) ) {
	foreach my $pkg ( @{ $opts->{ $realm }->{ $section } } ) {
	    my $pkg_config = $opts->{ $realm }->{ $section }->{ $pkg };

	    # make sure codebase defined
	    if ( $section eq 'packages' ) {
		if ( !$pkg_config->{codebase} ) {
		    WARN( "skipping processing of $realm->$section->$pkg: codebase not defined ");
		}
	    }

	    elsif ( $section eq 'services' ) {
		if ( $pkg_config->{codebase} ) {
		    INFO( "processing service $realm->$section->$pkg");
		}
	    }

	    my $codebase = $pkg_config->{codebase};
	    $codebase =~ s|/$||g;

	    my $source;
	    my $rsync_opts = { include => [] };

	    # copy 'include' section
	    foreach $source ( @{ $pkg_config->{include} } ) {
		my $fq = "$codebase/$source";
		if ( -d $source ) {
		    push @{ $rsync_opts->{include} }, $fq;
		}
		elsif ( -f $source ) {
		    push @{ $rsync_opts->{include} }, $fq;
		}
		else {
		    WARN( "skipping processing of $realm->$section->$pkg->include->$source: not a file or dir ");
		}
	    }
	    if ( @{ $rsync_opts->{include} } ) {
		$rsync_opts->{archive} = 1;
		File::Rsync::exec( $rsync_opts)
	    }

	    # process 'process' section
	    foreach $source ( @{ $pkg_config->{process} } ) {
		my $fq = "$codebase/$source";
		$self->process( $fq );
	    }

	    # process 'symlink' section
	    foreach $source ( @{ $pkg_config->{symlink} } ) {
		my $fq = "$codebase/$source";
		$self->symlink( $fq );
	    }
	}
    }
}

=head2 install

copies everything from build to install destination

=cut

sub install {

}

sub setup_apache {
    my $install_base = shift;

    # generate httpd conf and init files
    my $httpd_root  = $install_base . '/etc/httpd';
    my $httpd_lock  = $install_base . '/var/lock';
    my $httpd_run   = $install_base . '/var/run';
    my $httpd_log   = $httpd_root . '/logs';

    foreach my $cmd (
		     "mkdir -p $httpd_lock" ,
		     "mkdir -p $httpd_run" ,
		     "ln -sf /usr/lib/httpd/modules $httpd_root" ,
		     "mkdir -p $httpd_log" ,

		    ) {
	die "$cmd failed" unless !system( $cmd );
    }

}


#sub process {
#    my $dir  = $File::Find::dir; # is the current directory name,
#    my $file = $_;               # is the current filename within that directory
#    my $fq   = $File::Find::name; # is the complete pathname to the file.
#
#    $fq =~ m|^$install_base/usr/share/activator/catalyst/(.+)\.tt$|;
#    my $out = $1;
#    return unless $out;
#    $out =~ s/httpd$/$project-httpd/;
#
#    DEBUG( qq( processing $file into $install_base/$out ) );
#    my $tt = Template->new( { DEBUG => 1,
#			      ABSOLUTE => 1,
#			      OUTPUT_PATH  => $install_base,
#			    }
#			  );
#    $tt->process( $fq, $opts, $out ) || Activator::Log->logdie( $tt->error()."\n");
#    if( $out =~ m@/s?bin/|/init.d/@ ) {
#	chmod 0755, "$install_base/$out";
#    }
#}
