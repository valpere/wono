package Wono::Utils;

use strict;
use warnings 'all';
use utf8;

our $VERSION = 0.010;

use base qw( Exporter );

our @EXPORT_OK = qw(
    dump_data

    looks_like_json_string
    json_load
    json_save
    json_obj
    json_true
    json_false
    is_bool_json

    binary_load
    binary_save

    strip_spaces
    normalize_sentence
    purify_sentence
    normalize_word
    purify_word

    is_equal_num
    is_equal_str
    is_equal_bool

    to_array_ref
    flatten

    generate_fake_id

    copy_to_tmp_file
    create_tmp_file

    hash2array
    array2hash

    entropy
    evenness
);

our %EXPORT_TAGS = (
    json => [ qw(
            looks_like_json_string
            json_load
            json_save
            json_obj
            json_true
            json_false
            is_bool_json
            ),
    ],
    is_equal => [ qw(
            is_equal_num
            is_equal_str
            ),
    ],
    binary => [ qw(
            binary_load
            binary_save
            ),
    ],
);

use Const::Fast;
use POSIX qw(UINT_MAX);
use English qw(-no_match_vars);
use IO::File;
use File::Temp ();
use Cpanel::JSON::XS;
use Data::Dumper;
use Ref::Util qw(
    is_scalarref
);
use Clone qw(clone);
use Encode qw(
    encode_utf8
    decode_utf8
    is_utf8
);

#*****************************************************************************
const my $_RANDOM_RANGE => 100_000_000;

#*****************************************************************************
sub dump_data {
    my (@data) = @_;

    my $data;
    if ( @data < 1 ) {
        return '';
    }
    elsif ( @data > 1 ) {
        $data = [@data];
    }
    else {
        $data = $data[0];
    }

    if ( is_scalarref($data) ) {
        $data = ${$data};
    }

    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Terse    = 0;
    local $Data::Dumper::Indent   = 2;
    local $Data::Dumper::Useqq    = 0;
    local $Data::Dumper::Sortkeys = 1;

    $data = Dumper($data);
    $data =~ s/^\$VAR1\s*=\s*(.+);$/$1/s;

    return $data;
} ## end sub dump_data

#*******************************************************************************
sub looks_like_json_string {
    my ($str) = @_;

    return 0 if ( !$str );

    return ( ( $str =~ m/^\s*\{.*?\}\s*$/s ) || ( $str =~ m/^\s*\[.*?\]\s*$/s ) ) ? 1 : 0;
}

#***********************************************************************
sub json_save {
    my ( $file, $data ) = @_;

    my $json = json_obj()->pretty(1)->canonical(1)->utf8(1);

    return binary_save( $file, $json->encode($data) );
}

#***********************************************************************
sub json_load {
    my ($file) = @_;

    my $data = binary_load($file);
    if ( !$data ) {
        die("No content in file '$file'\n");
    }

    my $json = json_obj()->relaxed(1)->utf8(1);

    return $json->decode($data);
}

#***********************************************************************
sub convert_blessed_universally {
    my ($obj) = @_;

    require B;

    my $b_obj = B::svref_2object($obj);
    return
          $b_obj->isa('B::HV') ? { %{$obj} }
        : $b_obj->isa('B::AV') ? [ @{$obj} ]
        :                        undef;
}

#***********************************************************************
sub json_obj {
    my $json = Cpanel::JSON::XS->new();
    $json->utf8(0)->latin1(0);
    $json->allow_nonref(1);
    $json->allow_blessed(1);
    $json->convert_blessed(1);
    $json->allow_tags(1);

    no strict 'refs';    ## no critic (ProhibitNoStrict)
    *{'UNIVERSAL::TO_JSON'} = \&convert_blessed_universally;

    return $json;
}

#***********************************************************************
sub json_true {
    return Cpanel::JSON::XS::true;
}

#***********************************************************************
sub json_false {
    return Cpanel::JSON::XS::false;
}

#***********************************************************************
sub is_bool_json {
    my ($obj) = @_;

    return Cpanel::JSON::XS::is_bool($obj);
}

#***********************************************************************
sub binary_save {
    my ( $file, $data ) = @_;

    my $fh = IO::File->new( $file, 'w' ) || die("Can't create file '$file': $OS_ERROR\n");
    $fh->binmode(':bytes');
    my $res = $fh->print($data);
    $fh->close;

    return $res;
}

#***********************************************************************
sub binary_load {
    my ($file) = @_;

    local $INPUT_RECORD_SEPARATOR = undef;
    my $fh = IO::File->new( $file, 'r' ) || die("Can't open file '$file': $OS_ERROR\n");
    $fh->binmode(':bytes');
    my $data = <$fh>;
    $fh->close;

    return $data;
}

#*****************************************************************************
sub strip_spaces {
    my ( $str, $inside ) = @_;

    if ( !defined $str ) {
        return undef;
    }

    $str =~ s/^\s+//s;
    $str =~ s/\s+$//s;
    if ($inside) {
        $str =~ s/\s+/ /s;
    }

    return $str;
}

#*****************************************************************************
sub normalize_sentence {
    my ($sentence) = @_;

    if ( !defined $sentence ) {
        return undef;
    }

    if ( $sentence eq 'TL;DR' ) {
        return $sentence;
    }

    my $is_utf8 = is_utf8($sentence);

    $sentence = decode_utf8($sentence) if ( !$is_utf8 );

    $sentence =~ s/\s+/ /gs;

    $sentence =~ s/&amp;/&/g;
    $sentence =~ s/[’`´ʼ‘]+/'/g;
    $sentence =~ s/[«»«»”]+/"/g;
    $sentence =~ s/[…]+/.../g;
    $sentence =~ s/[º˚]+/°/g;
    $sentence =~ s/[‐‑]+/-/g;

    $sentence =~ s/[\x{2c8}\x{301}]+//g;    # наголос
    $sentence =~ s/[\x{0ad}]+//g;           # soft hyphen
    $sentence =~ s/([[:alnum:]])[–]+([[:alnum:]])/$1-$2/g;

    $sentence =~ s/""/" "/g;
    $sentence =~ s/''/' '/g;
    $sentence =~ s/"-"/" — "/g;

    $sentence =~ s/\s*[—–]+\s*/ — /g;
    $sentence =~ s/\s+[-]+\s+/ — /g;
    $sentence =~ s/([,:;])\s*/$1 /g;

    $sentence =~ s/^\s+//;
    $sentence =~ s/\s+$//;

    return $is_utf8 ? $sentence : encode_utf8($sentence);
} ## end sub normalize_sentence

#*****************************************************************************
sub purify_sentence {
    my ($sentence) = @_;

    if ( !defined $sentence ) {
        return undef;
    }

    my $is_utf8 = is_utf8($sentence);

    $sentence = $is_utf8 ? $sentence : decode_utf8($sentence);

    $sentence =~ s/<[^>]*>/ /sg;
    $sentence =~ s/[\(\)\[\]\{\}]+/ /sg;

    $sentence = normalize_sentence($sentence);

    my @words = split( m/\s+/, $sentence );

    my @result = ();
    for my $word (@words) {
        $word = purify_word($word);

        next if ( $word !~ m/[[:alnum:]]/ );

        push( @result, $word );
    }

    $sentence = join( ' ', @result );

    return $is_utf8 ? $sentence : encode_utf8($sentence);
} ## end sub purify_sentence

#*****************************************************************************
sub normalize_word {
    my ($word) = @_;

    if ( !defined $word ) {
        return undef;
    }

    my $is_utf8 = is_utf8($word);

    $word = decode_utf8($word) if ( !$is_utf8 );

    $word =~ s/^[^[[:alnum:]]+//;
    $word =~ s/[^[[:alnum:]]+$//;

    $word =~ s/([[:alnum:]])[–]+([[:alnum:]])/$1-$2/g;
    $word =~ s/[’`´ʼ‘]+/'/g;

    return $is_utf8 ? $word : encode_utf8($word);
}

#*****************************************************************************
sub purify_word {
    my ($word) = @_;

    if ( !defined $word ) {
        return undef;
    }

    my $is_utf8 = is_utf8($word);

    $word = lc( normalize_word( $is_utf8 ? $word : decode_utf8($word) ) );

    return $is_utf8 ? $word : encode_utf8($word);
}

#*****************************************************************************
sub is_equal_num {
    my ( $a, $b ) = @_;

    if ( !defined($a) && !defined($b) ) {
        return 1;
    }

    if ( defined($a) && defined($b) && ( $a == $b ) ) {
        return 1;
    }

    return 0;
}

#*****************************************************************************
sub is_equal_str {
    my ( $a, $b ) = @_;

    if ( !defined($a) && !defined($b) ) {
        return 1;
    }

    if ( defined($a) && defined($b) && ( $a eq $b ) ) {
        return 1;
    }

    return 0;
}

#*****************************************************************************
sub is_equal_bool {
    my ( $a, $b ) = @_;

    if ( !defined($a) && !defined($b) ) {
        return 1;
    }

    if ( defined($a) && defined($b) && ( $a && $b ) ) {
        return 1;
    }

    return 0;
}

#*****************************************************************************
sub to_array_ref {
    my ($value) = @_;

    if ( !defined($value) ) {
        return undef;
    }

    my $value_ref = ref($value);
    if ( !$value_ref ) {
        $value = [$value];
    }
    elsif ( $value_ref eq 'ARRAY' ) {
        # skip
    }
    else {
        $value = undef;
    }

    return $value;
} ## end sub to_array_ref

#*****************************************************************************
#** @function private flatten (@$array)
# @brief Flatten a nested array
#
# Produces a flat array out of a nested one weeding out duplicated
# items. For example, the following transformations will be performed:
#   - [1,2,3,4,5] -> [1,2,3,4,5];
#   - [1,[2,3],[4,5]] -> [1,2,3,4,5];
#   - [1,[2,[3,[4,[5]]]]] -> [1,2,3,4,5];
#   - [1,1,1,1,1] -> [1].
#
# @params @$array   reference to an array that contains scalars or
#                   nested arrays
# @retval @$array   reference to a copy of the input array that contains
#                   only unique scalars
#*
#-----------------------------------------------------------------------------
sub flatten {
    my ($array) = @_;

    my $flat_array = clone($array);

    my $len = scalar( @{$flat_array} );
    for my $i ( 0 .. $len - 1 ) {
        my $el = $flat_array->[$i];

        if ( is_bool_json($el) ) {
            next;
        }

        my $type = ref($el);
        if ( !$type ) {
            next;
        }

        if ( $type ne 'ARRAY' ) {
            fatalf( 'Unsupported ref type: %s', dump_data($el) );
        }

        splice( @{$flat_array}, $i, 1, @{$el} );
        # retry the same element to process nested arrays
        $len += scalar( @{$el} ) - 1;
        $i--;
    } ## end for my $i ( 0 .. $len -...)

    # filter out duplicated values
    my %seen;
    @{$flat_array} = grep { !$seen{ $_ // 'NULL' }++ } @{$flat_array};

    return $flat_array;
} ## end sub flatten

#*****************************************************************************
sub generate_fake_id {
    return UINT_MAX- int( rand($_RANDOM_RANGE) );
}

#*****************************************************************************
sub this {
    my $this = ( caller(1) )[3];
    $this =~ s/^.*:://;

    return $this;
}

#*****************************************************************************
sub hash2array {
    my ($hash) = @_;

    my $array = [];
    for my $name ( sort keys %{$hash} ) {
        my $item = $hash->{$name};
        $item->{name} = $name;

        push( @{$array}, $item );
    }

    return $array;
}

#*****************************************************************************
sub array2hash {
    my ($array) = @_;

    my %hash;
    for my $item ( @{$array} ) {
        my $name = delete( $item->{name} );
        $hash{$name} = $item;
    }

    return \%hash;
}

#*****************************************************************************
sub entropy {
    my ( $weight, $sum_weight ) = @_;

    my $p = $weight / $sum_weight;

    return -$p * log($p) * 1.44269504088896340737;    # 1/log(2)
}

#*****************************************************************************
sub evenness {
    my ( $entropy, $length ) = @_;

    return $entropy / log($length);
}

#*****************************************************************************
sub copy_to_tmp_file {
    my ( $file, $name_template ) = @_;

    $name_template //= 'tmpfile_XXXX';

    my $orig_key_fh = IO::File->new( $file, 'r' );
    if ( !$orig_key_fh ) {
        fatalf( 'Cannot open %s for reading', $file );
    }

    my ( $tmp_key_fh, $tmp_key ) = File::Temp::tempfile(
        'id_dsa_XXXX', SUFFIX => '.key', DIR => '/tmp', UNLINK => 1, OPEN => 1,
    );

    if ( !$tmp_key_fh ) {
        fatalf('Cannot create temp key file in /tmp');
    }

    while (<$orig_key_fh>) {
        print {$tmp_key_fh} $_;
    }

    if ( !$orig_key_fh->close() && !$tmp_key_fh->close() ) {
        fatalf('Impossible to close file handlers');
    }
    return $tmp_key;
} ## end sub copy_to_tmp_file

#*****************************************************************************
sub create_tmp_file {
    my ( $name, $dir ) = @_;

    $dir //= '/tmp';
    $name = ( $name // 'tmpfile' ) . '_XXXX';

    my ( undef, $tmpfile ) = File::Temp::tempfile(
        $name, DIR => $dir, UNLINK => 0, OPEN => 0,
    );
    return $tmpfile;
}

#*****************************************************************************
1;
__END__
