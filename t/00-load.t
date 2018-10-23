#!/usr/bin/env perl
package t_00_load;

use strict;
use warnings 'all';

use Test::More tests => 7;

use lib '../lib';

my @_CONSTANTS = qw(
    $DEFAULT_LIST_LIMIT
    $RETRY_LOGIN
    $SIGNAL_DIE
    $SIGNAL_WARN
    $SLEEP_BEFORE_RECONNECT
);

my @_UTILS = qw(
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
    array_diff
    array_intersection
    array_unique
    array_minus
    generate_fake_id
    base_name
    this
    entropy
    evenness
);

my @_LOGGER = qw(
    init_logger
    logger
    trace
    tracef
    traced
    debug
    debugf
    debugd
    debugdl
    info
    infof
    infod
    warning
    warningf
    warningd
    error
    errorf
    errord
    fatal
    fatalf
    fatald
);

BEGIN {
    use_ok('Wono::Constants', @_CONSTANTS);
    use_ok('Wono::Utils', @_UTILS);
    use_ok('Wono::Logger', @_LOGGER);
    use_ok('Wono::SQLMaker');
    use_ok('Wono::Driver');
    use_ok('Wono::Driver::SQL');
    use_ok('Wono');
};




#*****************************************************************************
1;
