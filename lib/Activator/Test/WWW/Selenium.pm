package Activator::Test::WWW::Selenium;

use Activator::Registry;
use Test::More;

use base qw/ Test::WWW::Selenium /;

=head1 NAME

Activator::Test::WWW::Selenium - Easy to use wrapper for selenium IDE generated tests

=head1 SYNOPSIS

=over

=item Use the following as the header for a perl Selenium IDE test:

 use strict;
 use warnings;
 use Time::HiRes qw(sleep);
 use Test::WWW::Selenium;
 use Test::More "no_plan";
 use Test::Exception;

 use Activator::Test::WWW::Selenium;
 my $sel = new Activator::Test::WWW::Selenium( @ARGV );

=item Use Selenium IDE to create tests such as:

 $sel->open_ok("/");
 $sel->is_text_present_ok("Seagate Firmware Performance Differences");

=item Save the test to where the Activator test harness can find it

 See 'perldoc Activator::Test::Harness::Selenium'

=back

=cut

=head1 DESCRIPTION

Selenium is an elegant framework for multi-platform multi-browser
testing. For more info on selenium, see:
  http://www.openqa.org/selenium/

This module provides an easy to use wrapper to Test::WWW::Selenium in
order to easily integrate with act-test.

=head1 SELENIUM RC SETUP

This test wrapper requires a remote server running Selenium RC
(SRC). That can be a build server, your workstation or any network
accessible machine that you have an account on and has jdk 1.5 or
greater. Do note that it must allow high port remote connections.

B<Windows>

  * Install the Java JDK v1.5 or greater from Sun:
      http://www.java.com/en/download/index.jsp
  * Install Selenium RC
    - download latest here: http://www.openqa.org/selenium-rc/download.action
    - unzip the package somwhere ( we use Desktop for this example )
    - open a command terminal ( WinKey-r then type 'cmd' )
    - cd to your desktop:
       cd "C:\Documents and Settings\user.name\Desktop"
    - read the help:
        java -jar selenium-remote-control-0.9.0\server\selenium-server.jar --help
    - start the server:
        java -jar selenium-remote-control-0.9.0\server\selenium-server.jar

B<Linux>
  * Install jdk >= 1.5
    sudo yum install jdk
  * Install Selenium RC
    - download latest here: http://www.openqa.org/selenium-rc/download.action
    - unzip the package somwhere ( $HOME is used for this example )
    - go to home dir:
        $ cd
    - read the help:
        $ java -jar selenium-remote-control-0.9.0/server/selenium-server.jar --help
    - start the server
        $ java -jar selenium-remote-control-0.9.0/server/selenium-server.jar

=head1 CREATING TESTS HOWTO

=head2 Install and Run Selenium IDE

 * Install the latest Selenium IDE Firefox plugin from here:
     http://www.openqa.org/selenium-ide/
 * restart Firefox
 * Select Tools->Selenium IDE from the menu

=head2 Update the Perl Export Format

 * Make sure Selenium IDE is running
 * Select Options->Options... from the IDE menu
 * Click the "Formats" tab
 * Click the "Perl - Selenium RC" format
 * Replace the following text:

   my $sel = Test::WWW::Selenium->new( host => "localhost",
                                       port => 4444,
                                       browser => "*firefox",
                                       browser_url => "http://localhost:4444" );

  with:
    use Activator::Test::WWW::Selenium;
    my $sel = new Activator::Test::WWW::Selenium( @ARGV );

=head2 Create A Selenium Test

 * Make sure Selenium IDE is running
 * Enter the URL you wish to test in the Base URL text input in Selenium IDE
 * Enter the URL you wish to test in the address bar of Firefox
 * Right-click on the page, select "open /path/to/your/url"
 * Now, do any seleniesque things you want
 * When done recording the test, select File->Export As-> ??TODO??
   from the Selenium IDE menu
 * Save/transfer the file to the package selenium test directory, probably:
     MyCatalystApp-Base/test/selenuim/<test_class>/<test_name>.t

=head2 Querying Databases From Tests

This is an example of accessing the default DB for the project from
within your test:

  use Activator::DB;
  my $sql  = "SELECT * from foo where x=? and y=?";
  my $vars = [ 1, 'string' ];
  my @row = &Activator::DB::getrow_array( $sql, $vars );
  my @expected_row = qw/ col1 col2 col3/;
  is( @row, @expected_row );

You can use any Test::More assertions you like. Please see perldoc for
Test::More and Activator::DB for more advanced usage.

=head2 Accessing YAML Configured Variables From Tests

When setting key/value pairs within the selenium: section of your role
or user yaml file, these variables are available through the
Activator::Test::WWW::Selenium $sel object with the 'get' command:

  use Activator::Registry;
  my $value = $sel->get( $key );

=head2 Using Alternate Login Users For Tests

All logins configured in the logins: section of your
Activator::Registry YAML config will be tested. Sometimes, this is not
desirable. You can set any number of logins in your <user>.yml as
such:

 selenium:

   # these will be used for all tests
   logins:
     user1:    passwd1
     user2:    passwd2
     user3:    passwd3

   # except this test, which only needs one login
   test_name:
     logins:
      - this_test_user: this_test_password


=head1 REGISTRY CONFIGURATION

=head2 Configure <project>.yml

This test framework is tightly integrated with Activator::Registry.
Setup the yaml file for your role with the following information:

 selenium:

   # Set some custom vars for just this test. Key must be exact
   # match to test filename.
   test_name:
     custom_var1: custom_value1
     custom_var2: custom_value2

   # for (sub)class tests, use colons (and single quotes) to
   # indicate heirarchy:
   'test_class::test_name':
     custom_var1: custom_value1
     custom_var2: custom_value2

   # URL for the version of the project you are testing
   base_url: 'http://somehost.internal/'

   # Optionally, Define any logins that can be used for test cases.  All will
   # be used, unless you override that in your test configuration. See section
   # Using Alternate Login Users For Tests
   logins:
     user1:    passwd1
     user2:    passwd2
     user3:    passwd3

   # login/logout test information
   login_link:     'link=log in'                   # link to click on to get to the login page
   login_username: 'login_email'                   # field to fill in for username
   login_password: 'login_password'                # field to fill in for password
   login_submit:   'document.forms[1].elements[4]' # element to click to login
   logout_link:    'link=Log Out'                  # link to click on to get to the login page

   # Define the Selenium RC hosts to run the tests on. This
   # section can be overridden in <user>.yml.
   test_hosts:
     knassar-workstation:     # descriptive label
       host:        10.1.2.42 # host name or IP address for the host running Selenium RC
       port:        4444      # port you have Selenium RC running. If unset, default 4444 is used.
       browsers:              # This section defines browsers to test in the format that Selenium needs.

     linux:  
       # Examples:
       host:     selenium-linux-qa
       port:     4444
       browsers:
         - *firefox /usr/lib/firefox-2.0.0.5/firefox-bin
         - *firefox /usr/lib/firefox-1.5.0.12/firefox-bin
  
     mac-osx:
       host:     selenium-mac-qa
       port:     4444
       browsers:
         - *safari /Applications/Safari.app/Contents/MacOS/Safari
         - *firefox /Applications/Firefox.app/Contents/MacOS/firefox-bin

     winXP-ie7:
       host:     selenium-windowsxp1-qa
       port:     4444
       browsers:
         - *iexplore
         - *firefox

     winXP-ie6:
       host:     selenium-windowsxp2-qa
       port:     4444
       browsers:
         - *iexplore

     winVista:  
       host:     selenium-windowsvista-qa
       port:     4444
       browsers:
         - *iexplore
         - *firefox
         - *opera
         - *safari

=head2 Configure user.yml

In your $USER.yml you should define any necessary variables you need
for any tests, or override any configurations settings as such:

 selenium:
   test_name.t:
     logins:
      - this_test_user: this_test_password
     key1: value1
     key2: value2
   test_hosts:
     my_workstation:
       host:        my_workstation.my_domain.com
       port:        5555
       browsers:
        - *firefox /usr/lib/firefox-2.0.0.5/firefox-bin

=head1 METHODS

=over

=item B<new>

This constructor is usually called by the test harness with all
variables set for this particular test to run.

 Args:
   $yaml => yaml file to load. See 'perldoc Activator::Test::Harness::Selenium'
            for configuration details

=cut

sub new {
    my ($pkg,
	$test,
	$host,
	$port,
	$browser,
	$base_url,
	$username,
	$password,
	$yaml)  = @_;

    if ( $yaml ) {
	&Activator::Registry::register_yml_file( $yaml );
    } elsif ( exists( $ENV{YAML_CONFIG} ) ) {
	&Activator::Registry::register_yml_file( $ENV{YAML_CONFIG} );
    } else {
	fatal("YAML_CONFIG env var not setup, and arg key 'yaml' not set.");
    }
    my $self = $pkg->SUPER::new( host => $host,
				 port => $port,
				 browser => $browser,
				 browser_url => $base_url,
				 default_names =>1,
			       );

    $self->{test} = $test;
    $self->{username} = $username;
    $self->{password} = $password;

    return bless $self, __PACKAGE__;
}

=item B<get>

Return the configured registry variable.

=cut

sub get {
    my ($self, $key) = @_;

    return Activator::Registry::get( 'selenium' )->{$self->{test}}->{$key};
}

=item B<login>
  Log in the user

  Args: $sel => object of type Test::WWW::Selenium
        $username -> optional username - defaults username passed into
                     constructor.
        $password => optional password - defaults username passed into
                     constructor. Use empty string for no password.

  See section REGISTRY CONFIGURATION for more information on how to automate logins

=cut

sub login_ok {
    my ( $self, $username, $passwd ) = @_;

    $username ||= $self->{username};
    $password ||= $self->{password};
    if(!defined($self->{username})) {
	diag('No user specified for test');
	return ok(0, 'login_ok');
    }
    elsif(!defined($self->{password})) {
	diag('No password specified for test');
	return ok(0, 'login_ok');
    }

    my $test_info = $self->get($self->{test}) || {};
    my $login_page     = $test_info->{login_page} || $self->get('login_page') || $self->{browser_url};
    my $login_click    = $test_info->{login_click} || $self->get('login_click');
    my $login_username = $test_info->{login_username} || $self->get('login_username');
    my $login_password = $test_info->{login_password} || $self->get('login_password');
    my $login_submit   = $test_info->{login_submit}  || $self->get('login_submit');

    $self->open($login_page);
    if ( $login_click ) {
	$self->click($login_click);
    }
    $self->type($login_username, $self->{username} );
    if ( $self->{password} ) {
	$self->type($login_password, $self->{password} );
    }
    $self->click($login_submit);
    $self->wait_for_page_to_load( "30000" );  # 30 sec

    return ok(1, 'login_ok');
}

=item B<logout>
  Log out user
  Set the logout/login link in 

  Args: $sel => object of type Test::WWW::Selenium

=cut

sub logout_ok {
    my ( $self ) = @_;
    my $test_info = $self->get($self->{test}) || {};
    my $logout_link = $test_info->{logout_link} || $self->get('logout_link');

    if(!$logout_link) {
	diag('No logout_link specified for test');
	return not_ok(1, 'logout_ok');
    }

    $self->click($logout_link);
    $self->wait_for_page_to_load( "30000" ); # 30 sec
    return ok(1, 'logout_ok');
}

=back

=cut

1;
