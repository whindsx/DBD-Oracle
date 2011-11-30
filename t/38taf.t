use strict;
use warnings;

use Test::More;

use DBI;
use DBD::Oracle;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';

my $dbh = eval { DBI->connect($dsn, $dbuser, '', ) } 
    or plan skip_all => "Unable to connect to Oracle";

plan tests => 1;

$dbh->disconnect;

$dbh = eval { 
    DBI->connect($dsn, $dbuser, '',{ora_taf=>1,taf_sleep=>15,ora_taf_function=>'taf'}) 
};   

if ( $dbh and $dbh->ora_can_taf ) {
    ok $dbh, 'basic connection';
}
else {
  like $@, qr/You are attempting to enable TAF|TAF support has been disabled for this instance of DBD::Oracle/, 
    'TAF not enabled';
}

