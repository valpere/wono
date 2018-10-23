package Wono::Driver::SQL;

use utf8;
use feature qw(state);

use Mouse;

extends 'Wono::Driver';

use DBI;
use Const::Fast;
use Ref::Util qw(
    is_hashref
);

# search for libs in module's directory
use FindBin qw($Bin);
use lib( $Bin, "$Bin/../.." );

use Wono::Logger qw(
    fatalf
    debugd
);

#*****************************************************************************
const my %_TABLE_EXISTS => (
    mysql => q{
SELECT table_name
  FROM information_schema.tables
 WHERE table_schema = SCHEMA();
    },
    oracle => q{
SELECT table_name
  FROM user_tables
    },
    sqlite => q{
SELECT name AS table_name
  FROM sqlite_master
 WHERE type='table'
    },
);

#*****************************************************************************
has 'dbh' => (
    is       => 'ro',
    isa      => 'Maybe[DBI::db]',
    lazy     => 1,
    required => 1,
    builder  => '_build_dbh',
    init_arg => undef,
    writer   => '_set_dbh',
);

has 'dsn' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'dbd' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'username' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'tables' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    required => 1,
    builder  => '_build_tables',
    init_arg => undef,
);

#*****************************************************************************
around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;

    my @dsn = DBI->parse_dsn( $args->{dsn} );
    if ( ( @dsn < 1 ) || !$dsn[1] ) {
        fatalf( 'Cannot parse DSN: %s', $args->{dsn} );
    }

    my $params = {
        %{$args},
        dbd => lc( $dsn[1] ),
    };

    return $class->$orig($params);
};

#*****************************************************************************
sub begin {
    my ($self) = @_;

    return ( defined( $self->dbh ) && $self->dbh->{AutoCommit} ) ? $self->dbh->begin_work : undef;
}

#*****************************************************************************
sub commit {
    my ($self) = @_;

    return ( defined( $self->dbh ) && $self->dbh->{BegunWork} ) ? $self->dbh->commit : undef;
}

#*****************************************************************************
sub rollback {
    my ($self) = @_;

    return ( defined( $self->dbh ) && $self->dbh->{BegunWork} ) ? $self->dbh->rollback : undef;
}

#**************************************************************************
sub do_one {
    my ( $self, $sql, $params ) = @_;

    ( $sql, $params ) = $self->_prepare_data( $sql, $params );

    my $ret = $self->dbh->do( $sql, undef, @{$params} );

    return $ret +0;
}

#**************************************************************************
sub get_val {
    my ( $self, $sql, $params ) = @_;

    ( $sql, $params ) = $self->_prepare_data( $sql, $params );

    my $sth = $self->dbh->prepare($sql);
    $sth->execute( @{$params} );

    my @row = $sth->fetchrow_array;

    return ( @row > 0 ) ? $row[0] : undef;
}

#**************************************************************************
sub get_one {
    my ( $self, $sql, $params ) = @_;

    ( $sql, $params ) = $self->_prepare_data( $sql, $params );

    my $sth = $self->dbh->prepare($sql);
    $sth->execute( @{$params} );

    return $sth->fetchrow_hashref();
}

#**************************************************************************
sub get_all {
    my ( $self, $sql, $params ) = @_;

    ( $sql, $params ) = $self->_prepare_data( $sql, $params );

    $self->dbh->{RaiseError} = 1;

    my $sth = $self->dbh->prepare( $sql, { ora_check_sql => 0 } );

    $sth->execute( @{$params} );

    my $list = [];
    while ( my $row = $sth->fetchrow_hashref() ) {
        push( @{$list}, $row );
    }

    return $list;
}

#**************************************************************************
sub get_all_hash {
    my ( $self, $sql, $params, $key_field ) = @_;

    ( $sql, $params ) = $self->_prepare_data( $sql, $params );

    return $self->dbh->selectall_hashref( $sql, $key_field, undef, @{$params} );
}

#**************************************************************************
sub table_exists {
    my ( $self, $table ) = @_;

    return exists( $self->tables->{ lc($table) } );
}

#**************************************************************************
sub get_map {
    my ( $self, $sql, $params ) = @_;

    ( $sql, $params ) = $self->_prepare_data( $sql, $params );

    my $sth = $self->dbh->prepare($sql);

    $sth->execute( @{$params} );

    my $hash = {};
    while ( my $row = $sth->fetchrow_hashref() ) {
        $hash->{ $row->{oid} } = $row->{nid};
    }

    return $hash;
}

#**************************************************************************
sub last_dbi_id {
    my ( $self, $args ) = @_;

    my $dbh = $self->dbh;

    if ( $self->dbd eq 'mysql' ) {
        return $dbh->{mysql_insertid};
    }
    elsif ( $self->dbd eq 'sqlite' ) {
        if ( is_hashref($args) ) {
            return $dbh->last_insert_id( $args->{catalog} || '', $args->{schema} || 'main', $args->{table} || '', $args->{field} || '' );
        }
        else {
            return $dbh->sqlite_last_insert_rowid;
        }
    }

    return undef;
}

#**************************************************************************
sub to_connect {
    my ($self) = @_;

    # $dbh->{AutoCommit}       = 1;
    # $dbh->{RaiseError}       = 1;
    # $dbh->{FetchHashKeyName} = 'NAME_lc';
    # $dbh->{LongReadLen} = 256 * 1024; # We're not expecting binary data of more than 256 KB

    my $dbh = DBI->connect( $self->dsn, $self->username, $self->password );
    if ( !$dbh ) {
        fatalf( '%s: %s', $DBI::errstr, $self->dsn );
    }

    return $dbh;
}

#**************************************************************************
sub to_disconnect {
    my ($self) = @_;

    if ( $self->dbh ) {
        $self->dbh->disconnect;
    }

    return undef;
}

#**************************************************************************
sub session_open {
    my ($self) = @_;

    my $dbh = $self->to_connect;

    $self->_set_dbh($dbh);

    return $dbh;
}

#**************************************************************************
sub session_close {
    my ($self) = @_;

    $self->to_disconnect;

    $self->_set_dbh(undef);

    return undef;
}

#**************************************************************************
sub _build_dbh {
    my ($self) = @_;

    return $self->to_connect;
}

#**************************************************************************
sub _build_tables {
    my ($self) = @_;

    my $list = $self->dbh->selectcol_arrayref( $_TABLE_EXISTS{ $self->dbd } ) || [];

    my %map;

    for my $table ( @{$list} ) {
        $map{ lc($table) } = 1;
    }

    return \%map;
}

#**************************************************************************
sub _prepare_data {
    my ( $self, $sql, $params ) = @_;

    my $values     = [];
    my $get_values = sub {
        my ($name) = @_;

        push( @{$values}, $params->{$name} );

        return '?';
    };

    $sql =~ s/:(\w+)/$get_values->($1)/ge;

    return ( $sql, $values );
}

#*****************************************************************************
no Mouse;
__PACKAGE__->meta->make_immutable;
#*****************************************************************************
1;
__END__
