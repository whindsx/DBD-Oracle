use strict;
use warnings;

use Test::More tests => 3;

use DBI; 
use utf8;

my $dbh = dbh( ora_charset => 'UTF8' ); 

$dbh->do( <<'END_SQL' );
    CREATE TABLE CITIES (  
        id NUMBER,
        text VARCHAR(100)
    )
END_SQL

my $city = "m\x{fc}chen";
utf8::upgrade($city);

$dbh->do( <<"END_SQL" );
    INSERT INTO CITIES VALUES (
        2, '$city'
    )
END_SQL

is_data_ok( $dbh ); 

$dbh->disconnect;

is_data_ok( dbh(ora_charset => 'AL32UTF8' ) ) for 1..2; 

dbh()->do( 'DROP TABLE CITIES' );


########## utility functions

sub dbh {
    DBI->connect( $ENV{ORACLE_DSN}, 'scott', 'tiger', 
        { @_ } 
    ); 
}

sub is_data_ok {
    my $dbh = shift;

    my $sth = $dbh->prepare("SELECT TEXT FROM CITIES WHERE id = '2'"); 

    $sth->execute();

    my $data = $sth->fetchrow_hashref(); 

    is $data->{TEXT} => $city;

    $sth->finish;
    $dbh->disconnect; 
} 



