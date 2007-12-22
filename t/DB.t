#!perl
use warnings;
use strict;

BEGIN{ 
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/DB-test.yml";
}

use Test::More tests => 52;
use Test::Exception;
use Activator::DB;
use Activator::Registry;
use Activator::Exception;

use Data::Dumper;
use DBI;
my ($dbh, $db, $id, $res, @row, $rowref, $err);

# create test dbs, users, tables
system( "cat $ENV{PWD}/t/data/DB-create-test.sql | mysql -u root");

# connect/select the old skool way
$dbh =  DBI->connect('DBI:mysql:act_db_test1:localhost', 'act_db_test_user', 'act_db_test_pass' );
ok( !$@, 'test old skool: DBI->connect without $@');
ok( !$DBI::err, 'no $DBI::err');
ok( !$DBI::errstr, 'no $DBI::errstr');
ok( $dbh, 'got dbh with DBI');
lives_ok { $dbh->ping() } 'ping $dbh with DBI';
@row = $dbh->selectrow_array( 'select * from t1' );
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row with DBI');

################################################################################
#
# connnect to the default db
#
lives_ok {
    $db = Activator::DB->connect('default')
} 'new skool: no connect error';
ok( defined( $db ) && $db->isa('Activator::DB'), 'valid default Activator::DB object');
ok( $db->{cur_alias} eq 'test1', 'alias set to test1');

# select default row
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row');

# connnect to alt db
lives_ok {
    $db = Activator::DB->connect('test2');
} 'no connect error';
ok( defined( $db ) && $db->isa('Activator::DB'), 'valid test2 Activator::DB object');
ok( $db->{cur_alias} eq 'test2', 'alias set to test2');

# select default row
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd2_t1_r1_c1' && $row[2] eq 'd2_t1_r1_c2', 'can select row from other db');

# select something that returns nothing, make sure we get empty row(ref) back
lives_ok {
    @row = $db->getrow( "select * from t1 where id = '-42'" );
} "getrow doesn't die";

ok( @row == 0, 'got empty array when select returns no rows' );

lives_ok {
    $rowref = $db->getrow_arrayref( "select * from t1 where id = '-42'" );
} "getrow_arrayref doesn't die";
ok( @$rowref == 0, 'got empty arrayref when select returns no rows' );

lives_ok {
    $rowref = $db->getrow_hashref( "select * from t1 where id = '-42'" );
} "getrow_hashref doesn't die";
ok( keys %$rowref == 0, 'got empty hashref when select returns no rows' );

# go back to default db
lives_ok {
    $db->connect();
} 'no connect error';
ok( defined( $db ) && $db->isa('Activator::DB'), 'reverted to valid default Activator::DB object');
ok( $db->{cur_alias} eq 'test1', 'alias reset to test1');

# select default row
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row from orig db');

# select using "change_alias"
lives_ok {
    @row = $db->getrow( 'select * from t1', [], connect =>'test2' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd2_t1_r1_c1' && $row[2] eq 'd2_t1_r1_c2', 'can select row from other db using connect');

# select staticly using connect
lives_ok {
    @row = Activator::DB->getrow( 'select * from t1', [], connect =>'test1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row from orig staticly');

# create a row
lives_ok {
    $id = Activator::DB->do_id( 'insert into t1 ( c1, c2) '.
				"values ( 'd1_t1_r2_c1', 'd1_t1_r2_c2')",
				[], connect => 'def', # should go back to test1
			      );
} "do_id doesn't die";
ok( $id && $id == 2, 'can insert' );
ok( $db->{cur_alias} eq 'test1', 'alias set to test1 using "def"');

# select the new row
lives_ok {
    @row = Activator::DB->getrow( "select * from t1 where id='$id'", [], connect => 'def' );
} "getrow doesn't die";
ok( $row[0] eq '2' && $row[1] eq 'd1_t1_r2_c1' && $row[2] eq 'd1_t1_r2_c2', 'can select new row');

# test "do"
lives_ok {
    $res = $db->do( "delete from t1 where id='$id'" );
} "do doesn't die";
ok( $res == 1, 'do affects corect num of rows');
lives_ok {
    @row = $db->getrow( "select * from t1 where id='$id'" );
} "getrow doesn't die";
ok( @row == 0, 'do successfully deleted row');

# fail on static calls without connect string
throws_ok {
    @row = Activator::DB->getrow( "select * from t1 where id='$id'" );
} 'Activator::Exception::DB', 'static call dies without connect arg';

throws_ok {
    @row = Activator::DB->getrow( "sel  from foo", [], connect => 'def');
} 'Activator::Exception::DB', 'invalid sql throws Activator::Exception::DB';

throws_ok {
    @row = Activator::DB->getrow( "select * from t1", [], connect => 'defasdlkj');
} 'Activator::Exception::DB', 'invalid connect alias dies';

# get row as arrayref
lives_ok {
    $rowref = $db->getrow_arrayref( "select * from t1" );
} "getrow_arrayref doesn't die after invalid connect attempt";
ok( ref($rowref) eq 'ARRAY', 'getrow_arrayref returns arrayref');
ok( @$rowref[0] eq '1' && @$rowref[1] eq 'd1_t1_r1_c1' && @$rowref[2] eq 'd1_t1_r1_c2', 'getrow_arrayref returns expected data');

# get row as hashref
lives_ok {
    $rowref = $db->getrow_hashref( "select * from t1" );
} "getrow_hashref doesn't die";
ok( ref($rowref) eq 'HASH', 'getrow_hashref returns hashref');
ok( $rowref->{id} eq '1' && $rowref->{c1} eq 'd1_t1_r1_c1' && $rowref->{c2} eq 'd1_t1_r1_c2', 'getrow_hashref returns expected data');

my $db2 = Activator::DB->connect('test1');
my $db3 = Activator::DB->connect('test2');
ok( $db2 eq $db3, 'multiple db objects refer to the same pointer' );

# force reconnect
$db->connect( 'test1');
delete $db->{connections}->{test1}->{dbh};
lives_ok {
    @row = $db->getrow( 'select * from t1' );
} "getrow doesn't die";
ok( $row[0] eq '1' && $row[1] eq 'd1_t1_r1_c1' && $row[2] eq 'd1_t1_r1_c2', 'can select row when dbh is missing');


# TODO: test getall_*

# delete test dbs, users, tables
system( "cat $ENV{PWD}/t/data/DB-drop-test.sql | mysql -u root");
