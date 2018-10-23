package Wono::SQLMaker;

use Mouse;

use Const::Fast;
use Ref::Util qw(
    is_ref
    is_arrayref
    is_hashref
);

# search for libs in module's directory
use FindBin qw($Bin);
use lib( $Bin, "$Bin/.." );

use Wono::Logger qw(
    debugd
);

#*****************************************************************************
const my $_QUOTE => {
    mysql     => '`',
    oracle    => '"',
    cassandra => '"',
};

#*****************************************************************************
const my $_RESERVED_WORDS => {
    # https://docs.oracle.com/database/121/SQLRF/ap_keywd001.htm#SQLRF55621
    oracle => {
        ACCESS          => 1,
        ADD             => 1,
        ALL             => 1,
        ALTER           => 1,
        AND             => 1,
        ANY             => 1,
        AS              => 1,
        ASC             => 1,
        AUDIT           => 1,
        BETWEEN         => 1,
        BY              => 1,
        CHAR            => 1,
        CHECK           => 1,
        CLUSTER         => 1,
        COLUMN          => 1,
        COLUMN_VALUE    => 1,
        COMMENT         => 1,
        COMPRESS        => 1,
        CONNECT         => 1,
        CREATE          => 1,
        CURRENT         => 1,
        DATE            => 1,
        DECIMAL         => 1,
        DEFAULT         => 1,
        DELETE          => 1,
        DESC            => 1,
        DISTINCT        => 1,
        DROP            => 1,
        ELSE            => 1,
        EXCLUSIVE       => 1,
        EXISTS          => 1,
        FILE            => 1,
        FLOAT           => 1,
        FOR             => 1,
        FROM            => 1,
        GRANT           => 1,
        GROUP           => 1,
        HAVING          => 1,
        IDENTIFIED      => 1,
        IMMEDIATE       => 1,
        IN              => 1,
        INCREMENT       => 1,
        INDEX           => 1,
        INITIAL         => 1,
        INSERT          => 1,
        INTEGER         => 1,
        INTERSECT       => 1,
        INTO            => 1,
        IS              => 1,
        LEVEL           => 1,
        LIKE            => 1,
        LOCK            => 1,
        LONG            => 1,
        MAXEXTENTS      => 1,
        MINUS           => 1,
        MLSLABEL        => 1,
        MODE            => 1,
        MODIFY          => 1,
        NESTED_TABLE_ID => 1,
        NOAUDIT         => 1,
        NOCOMPRESS      => 1,
        NOT             => 1,
        NOWAIT          => 1,
        NULL            => 1,
        NUMBER          => 1,
        OF              => 1,
        OFFLINE         => 1,
        ON              => 1,
        ONLINE          => 1,
        OPTION          => 1,
        OR              => 1,
        ORDER           => 1,
        PCTFREE         => 1,
        PRIOR           => 1,
        PUBLIC          => 1,
        RAW             => 1,
        RENAME          => 1,
        RESOURCE        => 1,
        REVOKE          => 1,
        ROW             => 1,
        ROWID           => 1,
        ROWNUM          => 1,
        ROWS            => 1,
        SELECT          => 1,
        SESSION         => 1,
        SET             => 1,
        SHARE           => 1,
        SIZE            => 1,
        SMALLINT        => 1,
        START           => 1,
        SUCCESSFUL      => 1,
        SYNONYM         => 1,
        SYSDATE         => 1,
        TABLE           => 1,
        THEN            => 1,
        TIMESTAMP       => 1,
        TO              => 1,
        TRIGGER         => 1,
        UID             => 1,
        UNION           => 1,
        UNIQUE          => 1,
        UPDATE          => 1,
        USER            => 1,
        VALIDATE        => 1,
        VALUES          => 1,
        VARCHAR         => 1,
        VARCHAR2        => 1,
        VIEW            => 1,
        WHENEVER        => 1,
        WHERE           => 1,
        WITH            => 1,
    },
    # https://dev.mysql.com/doc/refman/5.7/en/keywords.html
    mysql => {
        ACCESSIBLE                    => 1,
        ADD                           => 1,
        ALL                           => 1,
        ALTER                         => 1,
        ANALYZE                       => 1,
        AND                           => 1,
        ASC                           => 1,
        ASENSITIVE                    => 1,
        AS                            => 1,
        BEFORE                        => 1,
        BETWEEN                       => 1,
        BIGINT                        => 1,
        BINARY                        => 1,
        BLOB                          => 1,
        BOTH                          => 1,
        BY                            => 1,
        CALL                          => 1,
        CASCADE                       => 1,
        CASE                          => 1,
        CHANGE                        => 1,
        CHARACTER                     => 1,
        CHAR                          => 1,
        CHECK                         => 1,
        COLLATE                       => 1,
        COLUMN                        => 1,
        CONDITION                     => 1,
        CONSTRAINT                    => 1,
        CONTINUE                      => 1,
        CONVERT                       => 1,
        CREATE                        => 1,
        CROSS                         => 1,
        CURRENT_DATE                  => 1,
        CURRENT_TIMESTAMP             => 1,
        CURRENT_TIME                  => 1,
        CURRENT_USER                  => 1,
        CURSOR                        => 1,
        DATABASES                     => 1,
        DATABASE                      => 1,
        DAY_HOUR                      => 1,
        DAY_MICROSECOND               => 1,
        DAY_MINUTE                    => 1,
        DAY_SECOND                    => 1,
        DECIMAL                       => 1,
        DECLARE                       => 1,
        DEC                           => 1,
        DEFAULT                       => 1,
        DELAYED                       => 1,
        DELETE                        => 1,
        DESCRIBE                      => 1,
        DESC                          => 1,
        DETERMINISTIC                 => 1,
        DISTINCTROW                   => 1,
        DISTINCT                      => 1,
        DIV                           => 1,
        DOUBLE                        => 1,
        DROP                          => 1,
        DUAL                          => 1,
        EACH                          => 1,
        ELSEIF                        => 1,
        ELSE                          => 1,
        ENCLOSED                      => 1,
        ESCAPED                       => 1,
        EXISTS                        => 1,
        EXIT                          => 1,
        EXPLAIN                       => 1,
        FALSE                         => 1,
        FETCH                         => 1,
        FLOAT4                        => 1,
        FLOAT8                        => 1,
        FLOAT                         => 1,
        FORCE                         => 1,
        FOREIGN                       => 1,
        FOR                           => 1,
        FROM                          => 1,
        FULLTEXT                      => 1,
        GENERATED                     => 1,
        GET                           => 1,
        GRANT                         => 1,
        GROUP                         => 1,
        HAVING                        => 1,
        HIGH_PRIORITY                 => 1,
        HOUR_MICROSECOND              => 1,
        HOUR_MINUTE                   => 1,
        HOUR_SECOND                   => 1,
        IF                            => 1,
        IGNORE                        => 1,
        INDEX                         => 1,
        INFILE                        => 1,
        INNER                         => 1,
        INOUT                         => 1,
        INSENSITIVE                   => 1,
        INSERT                        => 1,
        INT1                          => 1,
        INT2                          => 1,
        INT3                          => 1,
        INT4                          => 1,
        INT8                          => 1,
        INTEGER                       => 1,
        INTERVAL                      => 1,
        INTO                          => 1,
        INT                           => 1,
        IN                            => 1,
        IO_AFTER_GTIDS                => 1,
        IO_BEFORE_GTIDS               => 1,
        IS                            => 1,
        ITERATE                       => 1,
        JOIN                          => 1,
        KEYS                          => 1,
        KEY                           => 1,
        KILL                          => 1,
        LEADING                       => 1,
        LEAVE                         => 1,
        LEFT                          => 1,
        LIKE                          => 1,
        LIMIT                         => 1,
        LINEAR                        => 1,
        LINES                         => 1,
        LOAD                          => 1,
        LOCALTIMESTAMP                => 1,
        LOCALTIME                     => 1,
        LOCK                          => 1,
        LONGBLOB                      => 1,
        LONGTEXT                      => 1,
        LONG                          => 1,
        LOOP                          => 1,
        LOW_PRIORITY                  => 1,
        MASTER_BIND                   => 1,
        MASTER_SSL_VERIFY_SERVER_CERT => 1,
        MATCH                         => 1,
        MAXVALUE                      => 1,
        MEDIUMBLOB                    => 1,
        MEDIUMINT                     => 1,
        MEDIUMTEXT                    => 1,
        MIDDLEINT                     => 1,
        MINUTE_MICROSECOND            => 1,
        MINUTE_SECOND                 => 1,
        MODIFIES                      => 1,
        MOD                           => 1,
        NATURAL                       => 1,
        NOT                           => 1,
        NO_WRITE_TO_BINLOG            => 1,
        NULL                          => 1,
        NUMERIC                       => 1,
        ON                            => 1,
        OPTIMIZER_COSTS               => 1,
        OPTIMIZE                      => 1,
        OPTIONALLY                    => 1,
        OPTION                        => 1,
        ORDER                         => 1,
        OR                            => 1,
        OUTER                         => 1,
        OUTFILE                       => 1,
        OUT                           => 1,
        PARTITION                     => 1,
        PRECISION                     => 1,
        PRIMARY                       => 1,
        PROCEDURE                     => 1,
        PURGE                         => 1,
        RANGE                         => 1,
        READS                         => 1,
        READ_WRITE                    => 1,
        READ                          => 1,
        REAL                          => 1,
        REFERENCES                    => 1,
        REGEXP                        => 1,
        RELEASE                       => 1,
        RENAME                        => 1,
        REPEAT                        => 1,
        REPLACE                       => 1,
        REQUIRE                       => 1,
        RESIGNAL                      => 1,
        RESTRICT                      => 1,
        RETURN                        => 1,
        REVOKE                        => 1,
        RIGHT                         => 1,
        RLIKE                         => 1,
        SCHEMAS                       => 1,
        SCHEMA                        => 1,
        SECOND_MICROSECOND            => 1,
        SELECT                        => 1,
        SENSITIVE                     => 1,
        SEPARATOR                     => 1,
        SET                           => 1,
        SHOW                          => 1,
        SIGNAL                        => 1,
        SMALLINT                      => 1,
        SPATIAL                       => 1,
        SPECIFIC                      => 1,
        SQL_BIG_RESULT                => 1,
        SQL_CALC_FOUND_ROWS           => 1,
        SQLEXCEPTION                  => 1,
        SQL_SMALL_RESULT              => 1,
        SQLSTATE                      => 1,
        SQLWARNING                    => 1,
        SQL                           => 1,
        SSL                           => 1,
        STARTING                      => 1,
        STORED                        => 1,
        STRAIGHT_JOIN                 => 1,
        TABLE                         => 1,
        TERMINATED                    => 1,
        THEN                          => 1,
        TINYBLOB                      => 1,
        TINYINT                       => 1,
        TINYTEXT                      => 1,
        TO                            => 1,
        TRAILING                      => 1,
        TRIGGER                       => 1,
        TRUE                          => 1,
        UNDO                          => 1,
        UNION                         => 1,
        UNIQUE                        => 1,
        UNLOCK                        => 1,
        UNSIGNED                      => 1,
        UPDATE                        => 1,
        USAGE                         => 1,
        USE                           => 1,
        USING                         => 1,
        UTC_DATE                      => 1,
        UTC_TIMESTAMP                 => 1,
        UTC_TIME                      => 1,
        VALUES                        => 1,
        VARBINARY                     => 1,
        VARCHARACTER                  => 1,
        VARCHAR                       => 1,
        VARYING                       => 1,
        VIRTUAL                       => 1,
        WHEN                          => 1,
        WHERE                         => 1,
        WHILE                         => 1,
        WITH                          => 1,
        WRITE                         => 1,
        XOR                           => 1,
        YEAR_MONTH                    => 1,
        ZEROFILL                      => 1,
    },
    # https://docs.datastax.com/en/cql/3.3/cql/cql_reference/keywords_r.html
    cassandra => {
        ADD          => 1,
        AGGREGATE    => 1,
        ALL          => 1,
        ALLOW        => 1,
        ALTER        => 1,
        AND          => 1,
        ANY          => 1,
        APPLY        => 1,
        AS           => 1,
        ASC          => 1,
        ASCII        => 1,
        AUTHORIZE    => 1,
        BATCH        => 1,
        BEGIN        => 1,
        BIGINT       => 1,
        BLOB         => 1,
        BOOLEAN      => 1,
        BY           => 1,
        CLUSTERING   => 1,
        COLUMNFAMILY => 1,
        COMPACT      => 1,
        CONSISTENCY  => 1,
        COUNT        => 1,
        COUNTER      => 1,
        CREATE       => 1,
        CUSTOM       => 1,
        DECIMAL      => 1,
        DELETE       => 1,
        DESC         => 1,
        DISTINCT     => 1,
        DOUBLE       => 1,
        DROP         => 1,
        EACH_QUORUM  => 1,
        ENTRIES      => 1,
        EXISTS       => 1,
        FILTERING    => 1,
        FLOAT        => 1,
        FROM         => 1,
        FROZEN       => 1,
        FULL         => 1,
        GRANT        => 1,
        IF           => 1,
        IN           => 1,
        INDEX        => 1,
        INET         => 1,
        INFINITY     => 1,
        INSERT       => 1,
        INT          => 1,
        INTO         => 1,
        KEY          => 1,
        KEYSPACE     => 1,
        KEYSPACES    => 1,
        LEVEL        => 1,
        LIMIT        => 1,
        LIST         => 1,
        LOCAL_ONE    => 1,
        LOCAL_QUORUM => 1,
        MAP          => 1,
        MATERIALIZED => 1,
        MODIFY       => 1,
        NAN          => 1,
        NORECURSIVE  => 1,
        NOSUPERUSER  => 1,
        NOT          => 1,
        OF           => 1,
        ON           => 1,
        ONE          => 1,
        ORDER        => 1,
        PARTITION    => 1,
        PASSWORD     => 1,
        PER          => 1,
        PERMISSION   => 1,
        PERMISSIONS  => 1,
        PRIMARY      => 1,
        QUORUM       => 1,
        RENAME       => 1,
        REVOKE       => 1,
        SCHEMA       => 1,
        SELECT       => 1,
        SET          => 1,
        STATIC       => 1,
        STORAGE      => 1,
        SUPERUSER    => 1,
        TABLE        => 1,
        TEXT         => 1,
        TIME         => 1,
        TIMESTAMP    => 1,
        TIMEUUID     => 1,
        THREE        => 1,
        TO           => 1,
        TOKEN        => 1,
        TRUNCATE     => 1,
        TTL          => 1,
        TUPLE        => 1,
        TWO          => 1,
        TYPE         => 1,
        UNLOGGED     => 1,
        UPDATE       => 1,
        USE          => 1,
        USER         => 1,
        USERS        => 1,
        USING        => 1,
        UUID         => 1,
        VALUES       => 1,
        VARCHAR      => 1,
        VARINT       => 1,
        VIEW         => 1,
        WHERE        => 1,
        WITH         => 1,
        WRITETIME    => 1,
    },
};

#*****************************************************************************
has 'dbd' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

#*****************************************************************************
sub is_oracle {
    my ( $self, $args ) = @_;

    return ( $self->dbd eq 'oracle' );
}

#*****************************************************************************
sub is_mysql {
    my ( $self, $args ) = @_;

    return ( $self->dbd eq 'mysql' );
}

#*****************************************************************************
sub is_cassandra {
    my ( $self, $args ) = @_;

    return ( $self->dbd eq 'cassandra' );
}

#*****************************************************************************
sub make_select {
    my ( $self, $args ) = @_;

    my ( $table, $object, $select, $join, $where, $clob_fields, $order_by, $limit, $offset )
        = @{$args}{qw(table object select join where clob_fields order_by limit offset)};

    my $data = {};

    my $sql = sprintf(
        'SELECT %s FROM %s %s WHERE %s %s',
        $self->_make_select($select),
        $table,
        $self->_make_join( $table, $join ),
        $self->_make_where( {
                table       => $table,
                fields      => $where,
                object      => $object,
                data        => $data,
                clob_fields => $clob_fields,
            }
        ),
        $self->_make_order_by($order_by),
    );

    $sql = $self->_make_limit( $sql, $limit, $offset );

    return ( $sql, $data );
} ## end sub make_select

#*****************************************************************************
sub make_count {
    my ( $self, $args ) = @_;

    my ( $table, $object, $join, $where, $clob_fields )
        = @{$args}{qw(table object join where clob_fields)};

    my $data = {};

    my $sql = sprintf(
        'SELECT COUNT(*) FROM %s %s WHERE %s',
        $table,
        $self->_make_join( $table, $join ),
        $self->_make_where( {
                table       => $table,
                fields      => $where,
                object      => $object,
                data        => $data,
                clob_fields => $clob_fields,
            }
        ),
    );

    return ( $sql, $data );
} ## end sub make_count

#*****************************************************************************
sub make_insert {
    my ( $self, $args ) = @_;

    my ( $table, $object, $fields ) = @{$args}{qw(table object fields)};

    my $data   = {};
    my @insert = ();
    my @values = ();
    for my $field ( @{$fields} ) {
        push( @insert, $self->_quote_field($field) );
        push( @values, ':' . $field );
        $data->{$field} = $object->{$field};
    }

    my $sql = sprintf(
        'INSERT INTO %s ( %s ) VALUES ( %s )',
        $table,
        join( ',', @insert ),
        join( ',', @values )
    );

    return ( $sql, $data );
} ## end sub make_insert

#*****************************************************************************
sub make_update {
    my ( $self, $args ) = @_;

    my ( $table, $object, $fields, $join, $where, $clob_fields )
        = @{$args}{qw(table object fields join where clob_fields)};

    my $data = {};

    my $sql = sprintf(
        'UPDATE %s %s SET %s WHERE %s',
        $table,
        $self->_make_join( $table, $join ),
        $self->_make_set( $fields, $object, $data ),
        $self->_make_where( {
                table       => $table,
                fields      => $where,
                object      => $object,
                data        => $data,
                clob_fields => $clob_fields,
            }
        ),
    );

    return ( $sql, $data );
} ## end sub make_update

#*****************************************************************************
sub make_delete {
    my ( $self, $args ) = @_;

    my ( $table, $object, $join, $where, $clob_fields, $pk )
        = @{$args}{qw(table object join where clob_fields pk)};

    my $data = {};

    $join = $self->_make_join( $table, $join );

    my $where_string = $self->_make_where( {
            table       => $table,
            fields      => $where,
            object      => $object,
            data        => $data,
            clob_fields => $clob_fields,
        }
    );

    my $sql;

    if ( $self->is_oracle && $join ) {
        $sql = sprintf(
            'DELETE FROM %s WHERE %s IN ( SELECT %s FROM %s %s WHERE %s )',
            $table,
            $pk,
            $pk,
            $table,
            $join,
            $where_string,
        );
    }
    else {
        $sql = sprintf(
            'DELETE FROM %s %s WHERE %s',
            $table,
            ( $join ? sprintf( ' USING %s %s ', $table, $join ) : '' ),
            $where_string,
        );
    }

    return ( $sql, $data );
} ## end sub make_delete

#*****************************************************************************
sub _make_select {
    my ( $self, $select ) = @_;

    if ( !is_hashref($select) ) {
        return '*';
    }

    my @select = ();
    foreach my $what ( sort keys %{$select} ) {
        if ( !$what ) {
            fatalf(q{Please specify correct parameters for 'select' predicate});
        }

        my ( $table, $key ) = split( /\./, $what, 2 );

        if ($key) {
            $table .= '.';
        }
        else {
            $key   = $table;
            $table = '';
        }

        my $value = $select->{$what};
        if ( !$value ) {
            push( @select, sprintf( '%s%s', $table, $self->_quote_field($key) ) );
        }
        else {
            push( @select, sprintf( '%s%s AS %s', $table, $self->_quote_field($key), $self->_quote_field($value) ) );
        }
    } ## end foreach my $what ( sort keys...)

    return join( ', ', @select );
} ## end sub _make_select

#*****************************************************************************
sub _make_join {
    my ( $self, $table, $join ) = @_;

    if ( !is_arrayref($join) ) {
        return '';
    }

    my @join      = ();
    my $join_type = '';
    foreach my $join_pair ( @{$join} ) {
        if ( !is_ref($join_pair) ) {
            $join_type = $join_pair;
            next;
        }

        my @join_on = ();
        my $join_table;
        while ( my ( $join_parent, $join_child ) = each( %{$join_pair} ) ) {
            my ( $join_ptab, $join_pkey );
            if ( index( $join_parent, '.' ) > -1 ) {
                ( $join_ptab, $join_pkey ) = split( /\./, $join_parent, 2 );
            }
            else {
                ( $join_ptab, $join_pkey ) = ( $table, $join_parent );
            }

            my ( $join_ctab, $join_ckey );
            if ( index( $join_child, '.' ) > -1 ) {
                ( $join_ctab, $join_ckey ) = split( /\./, $join_child, 2 );
            }
            else {
                ( $join_ctab, $join_ckey ) = ( $join_child, $join_pkey );
            }

            $join_table ||= $join_ctab;

            push( @join_on, sprintf( '%s.%s = %s.%s', $join_ptab, $self->_quote_field($join_pkey), $join_ctab, $self->_quote_field($join_ckey) ) );
        } ## end while ( my ( $join_parent...))

        push( @join, sprintf( '%s JOIN %s ON ( %s )', $join_type, $join_table, join( ' AND ', @join_on ) ) );
    } ## end foreach my $join_pair ( @{$join...})

    return join( ' ', @join );
} ## end sub _make_join

#*****************************************************************************
sub _make_where {
    my ( $self, $args ) = @_;

    my ( $table, $fields, $object, $data, $clob_fields ) = @{$args}{qw(table fields object data clob_fields)};

    if ( !$self->is_oracle ) {
        $clob_fields = {};
    }

    my @where = ();
    foreach my $field ( @{$fields} ) {
        if ( $field =~ m/^_/ ) {
            # see _make_set
            next;
        }

        my $value = $object->{$field};

        my $another_table = '';
        my $operation     = '=';
        if ( is_hashref($value) ) {
            if ( $value->{operation} ) {
                $operation = $value->{operation};
            }

            my $use_table = undef;
            if ( $value->{table} ) {
                $another_table = $value->{table};
            }

            $value = $value->{value};
        }

        my $use_table = '';
        if ( !$self->is_cassandra ) {
            $use_table = ( $another_table || $table );
        }

        if ( !defined($value) ) {
            if ( !$operation || ( $operation eq '=' ) ) {
                $operation = 'IS';
            }
            elsif ( ( $operation eq '!=' ) || ( $operation eq '<>' ) ) {
                $operation = 'IS NOT';
            }

            if ($use_table) {
                push( @where, sprintf( '%s.%s %s NULL', $use_table, $self->_quote_field($field), $operation ) );
            }
            else {
                push( @where, sprintf( '%s %s NULL', $self->_quote_field($field), $operation ) );
            }

            next;
        }

        if ( is_arrayref($value) ) {
            if ( !$operation || ( $operation eq '=' ) ) {
                $operation = 'IN';
            }
            elsif ( ( $operation eq '!=' ) || ( $operation eq '<>' ) ) {
                $operation = 'NOT IN';
            }

            if ($use_table) {
                push( @where, sprintf( q{%s.%s %s ( '%s' )}, $use_table, $self->_quote_field($field), $operation, join( q{', '}, @{$value} ) ) );
            }
            else {
                push( @where, sprintf( q{%s %s ( '%s' )}, $self->_quote_field($field), $operation, join( q{', '}, @{$value} ) ) );
            }

            next;
        }

        if ( exists( $clob_fields->{$field} ) ) {
            $self->_process_clob_field( {
                    field     => $field,
                    value     => $value,
                    where     => \@where,
                    data      => $data,
                    operation => $operation,
                }
            );

            next;
        }

        if ($use_table) {
            push( @where, sprintf( '%s.%s %s :%s', $use_table || $table, $self->_quote_field($field), $operation, $field ) );
        }
        else {
            push( @where, sprintf( '%s %s :%s', $self->_quote_field($field), $operation, $field ) );
        }

        $data->{$field} = $value;
    } ## end foreach my $field ( @{$fields...})

    return join( ' AND ', @where );
} ## end sub _make_where

#*****************************************************************************
sub _process_clob_field {
    my ( $self, $args ) = @_;

    my ( $field, $value, $where, $data, $operation ) = @{$args}{qw(field value where data operation)};

    my $clob_field = sprintf( 'to_char(%s)', $field );
    #to_char() handle empty string as null
    if ( !defined($value) || ( $value eq '' ) ) {
        if ( !$operation || ( $operation eq '=' ) ) {
            $operation = 'IS';
        }
        elsif ( ( $operation eq '!=' ) || ( $operation eq '<>' ) ) {
            $operation = 'IS NOT';
        }

        push( @{$where}, sprintf( '%s %s NULL', $self->_quote_field($clob_field), $operation ) );
    }
    else {
        push( @{$where}, sprintf( '%s %s :%s', $self->_quote_field($clob_field), $operation, $field ) );

        $data->{$field} = $value;
    }

    return undef;
} ## end sub _process_clob_field

#*****************************************************************************
sub _make_order_by {
    my ( $self, $order_by ) = @_;

    if ( !is_arrayref($order_by) ) {
        return '';
    }

    my @order_by = ();
    for my $row ( @{$order_by} ) {
        if ( is_arrayref($row) ) {
            push( @order_by, sprintf( '%s %s', $self->_quote_field( $row->[0] ), uc( $row->[1] ) ) );
        }
        else {
            push( @order_by, sprintf( '%s', $self->_quote_field($row) ) );
        }
    }

    my $sql = '';
    if ( @order_by > 0 ) {
        $sql = sprintf( ' ORDER BY %s', join( ', ', @order_by ) );
    }

    return $sql;
} ## end sub _make_order_by

#*****************************************************************************
sub _make_limit {
    my ( $self, $sql, $limit, $offset ) = @_;

    if ( !$limit ) {
        return $sql;
    }

    if ( $self->is_oracle ) {
        return $offset
            ? sprintf(
            'SELECT * FROM ( SELECT lim1# .* , ROWNUM rnum1 FROM ( %s ) lim1# WHERE ROWNUM <= %d ) WHERE rnum1 > %d',
            $sql, $offset + $limit, $offset
            )
            : sprintf( 'SELECT lim1# .* FROM ( %s ) lim1# WHERE ROWNUM <= %d', $sql, $limit );
    }
    else {
        return $offset
            ? sprintf( '%s LIMIT %d OFFSET %d', $sql, $limit, $offset )
            : sprintf( '%s LIMIT %d',           $sql, $limit );
    }

    return $sql;
} ## end sub _make_limit

#*****************************************************************************
sub _make_set {
    my ( $self, $fields, $object, $data ) = @_;

    my @sets = ();
    for my $field ( @{$fields} ) {
        # if you want to do something like this:
        # UPDATE Table
        # SET    i_customer = 3
        # WHERE  i_customer = 2
        #
        # $object = {
        #    i_customer => 2,
        #    _i_customer => 3,
        # };
        #
        # $fields = ['_i_customer'];

        my $key = $field;
        $key =~ s/^[_]+//;

        push( @sets, sprintf( '%s = :%s', $self->_quote_field($key), $field ) );
        $data->{$field} = $object->{$field};
    }

    return join( ',', @sets );
} ## end sub _make_set

#**************************************************************************
sub _quote_field {
    my ( $self, $field ) = @_;

    my $dbd = $self->dbd;
    if ( exists( $_RESERVED_WORDS->{$dbd}->{ uc($field) } ) ) {
        return sprintf( '%s%s%1$s', $_QUOTE->{$dbd}, $field );
    }

    return $field;
}

#*****************************************************************************
1;
__END__
