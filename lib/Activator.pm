package Activator;

our $version = '.10';

1;

__END__

=head1 NAME

Activator Development Framework - Object Oriented framework to ease
creation of mulit-developer distributed mixed environment perl based
software projects, especially Catalyst based websites.

=head1 DESCRIPTION

NOTE: This set of modules is under heavy change and active
development. Contact the author before using.

=head2 Motivation

=over

=item *

Provide a framework that makes it easy to do OO programming in Perl.

=item *

Create a centralized configuration that plays nice with other projects using the same framework.

=item *

Play extra nice with Catalyst, but provide framework for any Perl project.

=item *

Maintain a strong separation between the 3 parts of an MVC codebase.

=item *

Provide tools so that crons, command line tools, and web site code all play nice together.

=item *

Provide I18N that works across all aspects of a project.

=item *

Provide Database access that works across all aspects of a project.
  Optionally, force programmers to write SQL.

=item *

Allow multiple developers on the same or distributed machines to play nice together.

=back

=head1 TODO

This section lists known issues and desired functionality.

=head2 Activator (this file)

=over


=item *

Create full project documentation

=item *

Create Cookbook section

=back

=head2 Activator::Registry

=over

=item *

Complete variable replacement implementation. Some variables should come from C<%ENV> (like C<USER>)

=item *

support get() of deep keys with indirect notation. eg:

     Activator::Registry->get('top->deep->deeper');

=item *

Utilize L<Hash::Merge> custom precedence to DEBUG non-existent keys
when calling C<register_hash()> with C<right> precedence.

=item *

Make currently commented out L<Hash::Merge> custom precedence
C<SAFE_LEFT_PRECEDENCE> work when mixing/matching types with C<left>
or C<right> C<register_hash()>

=back

=head2 Activator::Exception

=over

=item *

Make this thing do dictionary/lexicon lookups, with support in $extra
as well.

=item *

Make C<full_message>this take 2 args, update all of Activator.

=item *

implement C<as_xml()> and C<as_json()>

=item *

Investigate a way to add the file:line where the exception was thrown
into the error message.

=back

=head2 Activator::Log

=over

=item *

create tests for setting default log levels via new and config

=back

=head2 Activator::Dictionary

=over

=item *

enforce realm naming conventions listed in RESERVED WORDS FOR REALMS section

=item *

make config of 'db_alias' connections consistent with Act::DB terminology

=item *

Document what lookup returns for DB with multiple cols. Or, consider
removing this functionality altogether: make it only do
realm,key,value,lang

=back

=head2 Activator::Options

=over

=item *

support variable replacement from Registry

=item *

Support Conf File Search Path via command line, ENV and Registry.
Also, when a config file does not exist or is ignored, warn which
search path it was missing/discovered from.

=item *

Create a C<lint> hash within each realm that has the identical
heirarchy as the realm itself, except values are where the variable
was set.

=item *

consider supporting realm specific command line options the same way as ENV

=item *

support extra config files that can be injected via command line,ENV
and Registry. For example:

    * knassar-apache.yml   # user apache config
    * dev-apache.yml       # dev realm apache config
    * project-apache.yml   # project apache config
    * org-apache.yml       # org apache config

    via command line : --conf_files=apache,foo,bar
    via env vars     : export ACT_OPT_conf_files=apache,foo,bar
    via yaml         : conf_files: [ apache, foo, bar ]

=back

=head2 Activator::Options

=over

=item *

implement

=back

=head2 act-sync.pl

=over

=item *

Remove the rebates project implementation, replace with real implementation.

=item *

Utilize L<Activator::Project>, whenever that gets implemented

=back

=head2 Catalyst::Plugin::SecureCookies

=over

=item *

Consider pulling out base64 stuff and utilize an existing lib. Seems a
little hoaky as implemented.

=back

=head2 Catalyst::Plugin::SecureForms

=over

=item *

implement

=back

=head2 Catalyst::Plugin::Activator::Dictionary

=over

=item *

=back

=head2 Catalyst::Plugin::YUI

=over

=item *

Consider implementing some magic to make YUI integration trivail.
Should import the YUI (js/css/etc) on the fly with some simple syntax
in a template.

=back

=head2 Catalyst::Plugin::Activator::Ajax

=over

=item *

should provide XML or JSON response wrapper. NOTE: this needs
research, as there probably is an easy way to do this already.

=item *

Do not return HTML, or if you have to, place in CDATA

=item *

allow passing a .tt to xml_response

=item *

build json_response?

=back

=head2 Activator::DB

=over

=item *

support some sort of SIGHUP to reload the config on the fly

=item *

Add support for other DBs. specifically, support mysql_auto_reconnect via a config option.

=item *

support debugging of C<attr> hash in C<_get_sql()>

=back

=head2 Activator::DB::SQLFactory

=over

=item *

Implement a query builder

=item *

have it use L<Activator::Pager>

=back

=head2 Activator::Memcache

=over

=item *

Implement a simple wrapper to memcached that utilizes the registry.
Should be a singleton with static calls.

=back

=head2 Activator::Cron

=over

=item *

implement

=back

=head2 Activator::WWW::Util

=over

=item *

Research existing modules on CPAN, implement non-existing stuff.

=back

=head2 Catalyst::Plugin::Activator::Exception

=over

=item *

support C<as_json> and C<as_xml> when L<Activator::Exception> does.

=item *

consider renaming C<throw> to C<toss> or something. Throw dies
everywhere else but here.

=back

=head2 Catalyst::Plugin::Activator::WWW::Util

=over

=item *

wrapper for the above

=back

=head2 Activator::WWW::AdminTool

=over

=item *

port the RJ admintool into Activator::WWW::AdminTool

=back

=head2 Activator::Test

=over

=item *

create test wrapper that is Registry configurable

=back

=head2 Activator::Test::WWW::Selenium

=over

=item *

fix up to be Activator ready

=back

=head2 Activator::Test::Harness::Selenium

=over

=item *

fix up to be Activator ready

=back

=head2 Activator::Pager

=over

=item *

implement getter functions to be more OO, instead of direct obj access

=back

=head2 Activator::Lexicon

=over

=item *

implement subclass to L<Locale::Maketext> that respects the
L<Activator::Dictionary> interface

=back

=head1 SEE ALSO

 L<Activator::DB>
 L<Activator::Registry>
 L<Activator::Exception>
 L<Activator::Log>
 L<Activator::Pager>
 L<Activator::Dictionary>
 L<Activator::Options>

=head1 AUTHOR

Karim Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
