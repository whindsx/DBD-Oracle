use strict;
use warnings;

use Test::More;

unshift @INC, 't';
require 'nchar_test_lib.pl';

my $dbh = DBI->connect( oracle_test_dsn(), split( '/', $ENV{ORACLE_USERID} || 'scott/tiger' ), { PrintError => 0 } );

my $table = 'gh18';

$dbh->do( "DROP TABLE $table" );

$dbh->do( <<"SQL" );
    CREATE TABLE $table (
        ID                   NUMBER(12)               NOT NULL,
        CLIENT_ID            NUMBER(12)               NOT NULL,
        ARCHIVE_STATUS       VARCHAR2(10 BYTE)        NOT NULL
    )
SQL

my $sth = $dbh->prepare( "INSERT INTO $table (id, client_id, archive_status) values  (?,?,?)" );

my @vals = (
    [ 3912977, 1, 'PIG' ],
    [ 3912992, 1, 'PIG' ],
    [ 197265, 2, 'PIG' ],
    [ 197266, 2, 'PIG' ],
    [ 197276, 2, 'PIG' ],
);

for my $vals ( @vals ) {
    $sth->execute( @$vals );
}

my @col1 = (3912977,3912992,197265,197266,197276);
my @col2 = (1,1,2,2,2);
my @col3 = ('CAT','DOG','XXXXXXXXXXXXXXXXXXXXX','DOG','DOG');

bulk_update($dbh, \@col1, \@col2, \@col3);

$sth = $dbh->prepare("SELECT * from $table" );
$sth->execute;

while( my $row = $sth->fetchrow_arrayref ) {
    print join " ", @$row;
    print "\n";
}

sub bulk_update {
  my ($dbh, $r_id, $r_cl_id, $r_arch_stat) = @_;
  $dbh->{"RaiseError"} = 1;
  $dbh->{"AutoCommit"} = 0;


  my $sth = $dbh->prepare( qq{UPDATE $table set archive_status = ?  where id = ? and client_id = ?} );
  eval {
    $sth->bind_param_array( 1, $r_arch_stat );
    $sth->bind_param_array( 2, $r_id );
    $sth->bind_param_array( 3, $r_cl_id );
  };
  if ($@) {
    die $dbh->errstr;
  }

  my $tuples;
  my @tup_status;
  eval {
    $tuples = $sth->execute_array ( { ArrayTupleStatus => \@tup_status } );
  };
  if($@) {
    #print 'ROW', Dumper \@tup_status;
    if (! defined $tuples) {
      for my $tuple (0..@{$r_cl_id}-1) {
        my $status = $tup_status[$tuple];
        $status = [0, "Skipped"] unless defined $status;
        next unless ref $status;

        warn "Failed to insert [" .
              ${$r_id}[$tuple] . ':' .
              ${$r_cl_id}[$tuple] .':' .
              ${$r_arch_stat}[$tuple] . "]\n" .
              $status->[1];
      }
    }
    else {
      $dbh->rollback();
      die "Fatal error in execute_array\n" . $dbh->errstr;
    }
  }
  $dbh->commit();
}

