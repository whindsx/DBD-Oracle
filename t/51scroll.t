#!/usr/bin/perl

use strict;
use Test::More;
use DBD::Oracle qw(:ora_types :ora_fetch_orient :ora_exe_modes);
use DBI;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

## ----------------------------------------------------------------------------
## 51scroll.t
## By John Scoles, The Pythian Group
## ----------------------------------------------------------------------------
##  Just a few checks to see if one can use a scrolling cursor
##  Nothing fancy.
## ----------------------------------------------------------------------------

# create a database handle
my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh;
eval {$dbh = DBI->connect($dsn, $dbuser, '', { RaiseError=>1,
                                               AutoCommit=>1,
                                               PrintError => 0 })};
if ($dbh) {
    plan tests => 32;
} else {
    plan skip_all => "Unable to connect to Oracle";
}
ok ($dbh->{RowCacheSize} = 10);

# check that our db handle is good
isa_ok($dbh, "DBI::db");

my $table = table();


$dbh->do(qq{
	CREATE TABLE $table (
	    id INTEGER )
    });


my ($sql, $sth,$value);
my $i=0;
$sql = "INSERT INTO ".$table." VALUES (?)";

$sth =$dbh-> prepare($sql);

for my $i (1..10){
   $sth-> bind_param(1, $i);
   $sth->execute();
}

$sql="select * from ".$table;
ok($sth=$dbh->prepare($sql,{ora_exe_mode=>OCI_STMT_SCROLLABLE_READONLY,ora_prefetch_memory=>200}));
ok ($sth->execute());

#first loop all the way forward with OCI_FETCH_NEXT
for my $i ( 1..10 ) { 
   $value =  $sth->ora_fetch_scroll(OCI_FETCH_NEXT,0);
   is $value->[0] => $i, '... we should get the next record';
}


$value =  $sth->ora_fetch_scroll(OCI_FETCH_CURRENT,0);
is $value->[0] => 10, '... we should get the 10th record';

#now loop all the way back
for my $i ( reverse 1..9 ) {
   $value =  $sth->ora_fetch_scroll(OCI_FETCH_PRIOR,0);
   is $value->[0] => $i, '... we should get the prior record';
}

#now +4 records relative from the present position of 0;

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,4);
is $value->[0] => 5, '... we should get the 5th record';

#now +2 records relative from the present position of 4;

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,2);
is $value->[0] => 7, '... we should get the 7th record';

#now -3 records relative from the present position of 6;

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,-3);

is $value->[0] => 4, '... we should get the 4th record';

#now get the 9th record from the start
$value =  $sth->ora_fetch_scroll(OCI_FETCH_ABSOLUTE,9);

is $value->[0] => 9, '... we should get the 9th record';

#now get the last record

$value =  $sth->ora_fetch_scroll(OCI_FETCH_LAST,0);

is $value->[0] => 10, '... we should get the 10th record';

#now get the ora_scroll_position

is $sth->ora_scroll_position => 10, '... we should get the 10 for the ora_scroll_position';

#now back to the first

$value = $sth->ora_fetch_scroll(OCI_FETCH_FIRST,0);
is $value->[0] => 1, '... we should get the 1st record';

#check the ora_scroll_position one more time

is $sth->ora_scroll_position => 1, '... we should get the 1 for the ora_scroll_position';

my $other_value =  $sth->ora_fetch_scroll(OCI_FETCH_LAST,0);
is $other_value->[0] => 10, 'fetched the last value';
is $value->[0] => 1, q{...which shouldn't change the first one};


$sth->finish;
drop_table($dbh);


$dbh->disconnect;
