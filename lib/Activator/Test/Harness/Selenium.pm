package Activator::Test::Harness::Selenium;

use Test::Harness;
use Activator::Registry;

=head1 NAME

Activator::Test::Harness::Selenium - Harness to run selenium IDE
generated tests on multiple platforms easily

=head1 SYNOPSIS

THIS IS NOT COMPLETE AND WILL NOT WORK AS IMPLEMENTED. Needs to be
converted to work with L<Activator>.

 * Use selenium IDE to gernerate a test file "testfile.t"

 * Save the file to the package's test/selenuim/ directory (probably
   in package perl-MyCatalystApp-Base) in any directory heirarchy you
   desire.

 * Run the test:
     act-test --selenium test_name1.t

=head1 DESCRIPTION

Selenium is an elegant framework for multi-platform multi-browser
testing. For more info on selenium, see:
  http://www.openqa.org/selenium/

This module provides a harness for 'act-test' to allow easy
integration with Selenium IDE.

If you have the suggested layout of:
   perl-MyCatalystApp-Base/test/selenium/test_name1.t
   perl-MyCatalystApp-Base/test/selenium/test_class/test_name2.t
   perl-MyCatalystApp-Base/test/selenium/test_class/test_subclass/test_name3.t

you can:

 * Run all tests:
      act-test --selenium :ALL:

 * Or, run a particular test:
      act-test --selenium test_name1.t
      act-test --selenium test_class/test_name2.t
      act-test --selenium test_class/test_subclass/test_name3.t

 * Or, run a particular (sub)class of tests:
     act-test --selenium my_test_class
     act-test --selenium my_test_class/my_test_subclass

See perldoc 'perldoc Activator::Test::WWW::Selenium' for how to create
and setup these tests.


=head1 METHODS

=over

=item B<new>()

Constructor.

=cut

sub new {
    my $pkg=shift;

    my ($config, $passed, $failed, $warnings)=
	kwargs("${pkg}::new", \@_,
	       qw(config passed failed warnings));

    my $self = { config => $config,
		 passed => $passed,
		 failed => $failed,
		 warnings => $warnings,
	       };
    return bless $self, $pkg;
}

sub run {
    my ($self, $tests) = @_;

    # setup
    my $sel_config = $self->{config}->{selenium};

    # coerce the selenium config into the format that VarRegistry
    # wants to make the test wrapper nice and simple.
    my $tmp_yaml_file = '/tmp/ocd-selenium-harness-'.rand;

    # THIS LINE BROKEN
    YAML::DumpFile( $tmp_yaml_file, { 'Activator::Registry->test' => 
				      { selenium => $self->{config}->{selenium} } } );

    say( "Running Selenium Tests:" );
    # loop over the hosts->browsers->tests->logins
    foreach my $host ( keys %{ $sel_config->{test_hosts} } ) {
	my $host_ref = $sel_config->{test_hosts}->{$host};
	foreach my $browser ( @{$host_ref->{browsers}} ) {
	    foreach my $path ( keys %$tests) {
		say("Running under path '$path'");
		foreach my $test ( keys %{$tests->{$path}} ) {

		    my $logins =
		      $sel_config->{ $test }->{logins} ||
			$sel_config->{logins};

		    my $base_url =
		      $sel_config->{ $test }->{base_url} ||
			$sel_config->{base_url} ||
			  fatal( 'invalid selenium config: base_url not set' );

		    # setup none key to allow the next foreach
		    if ( ! keys %$logins ) {
			$logins->{none} = '';
		    }

		    my $file = $test;
		    $file =~ s|::|/|g;

		    # XXX: KN
		    # Should fork here for parallelizationocitifity!
		    foreach my $user ( keys %$logins ) {
			my ($pretty_browser)=$browser=~m/(iexplore|firefox|safari|opera)/;
			$pretty_browser ||= $browser;
			say("Running test '$test' host=>$host browser=>$pretty_browser login=>$user base_url=>$base_url");
			my $outp = backticks (
                                              'perl',
					      "$path/$file.t",
					      $test,
					      $host_ref->{host},
					      $host_ref->{port},
					      $browser,
					      $base_url,
					      ( $user ne 'none' ? $user : '' ),
					      ( $user ne 'none' ? $logins->{ $user } : '' ),
					      $tmp_yaml_file
					    );
			if ($?){
			    fatal("$path/$file.t failed: $?\n$outp");
			}
			say($outp);
			my @outp = split /\n/, $outp;
			foreach my $line ( @outp ) {
			    if ( $line =~ /^not ok \d+ - (.+)/ ) {
				push(@{$self->{failed}}, "$file: $1");
			    }
			    elsif ( $line =~ /^ok \d+ - (.+)/ ) {
				push(@{$self->{passed}}, "$file $1");
			    }
			}
		    }
		}
	    }
	}
    }
    print "\n";
}

=back

=cut

1;
package Activator::Test::Harness::Selenium;

