package Wono::Constants;

use strict;
use warnings 'all';
use utf8;

our $VERSION = 0.010;

use base qw( Exporter );

our @EXPORT_OK = qw(
    $DEFAULT_LIST_LIMIT

    $RETRY_LOGIN

    $SIGNAL_DIE
    $SIGNAL_WARN

    $SLEEP_BEFORE_RECONNECT
);

our %EXPORT_TAGS = ();

use Const::Fast;

#*****************************************************************************

const our $DEFAULT_LIST_LIMIT => 1000;

const our $RETRY_LOGIN => 3;    # Number of attempts to re-login

const our $SIGNAL_DIE  => '__DIE__';
const our $SIGNAL_WARN => '__WARN__';

const our $SLEEP_BEFORE_RECONNECT => 10;

#*****************************************************************************
1;
__END__
