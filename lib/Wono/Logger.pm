package Wono::Logger;

#*****************************************************************************
# The module Implements logging via <http://mschilli.github.io/log4perl>.
#-----------------------------------------------------------------------------

use strict;
use warnings 'all';
use utf8;

our $VERSION = 0.010;

use base qw( Exporter );

our @EXPORT_OK = qw(
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

use Carp qw(
    longmess
    shortmess
);
use Log::Log4perl qw(
    :levels
    get_logger
);

# search for libs in module's directory
use FindBin qw($Bin);
use lib( $Bin, "$Bin/.." );

use Wono::Utils qw(
    dump_data
);

#*****************************************************************************
#** @function public init_logger(%$config, $signal)
# @brief Initialize the logger
# @param %config                configuration: file, HASHREF, SCALARREF
# @param $signal         scalar, listen for an Unix signal to reload the configuration
# @return scalar, undef
#*
#-----------------------------------------------------------------------------
sub init_logger {
    my ( $config, $signal ) = @_;

    if ($signal) {
        Log::Log4perl->init_and_watch( $config, $signal );
    }
    else {
        Log::Log4perl->init($config);
    }

    return undef;
}

#*****************************************************************************
#** @function public trace($message)
# @brief Logging scalar message in 'debug' level and with tracing calls
# @param $message   scalar, simple text
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub trace {
    my ($message) = @_;

    return logger( 'trace', 1, $message );
}

#*****************************************************************************
#** @function public tracef($format, @params)
# @brief Logging formatted message in 'debug' level and with tracing calls.
# @param $format   scalar, message format
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub tracef {
    return logger(
        'trace',
        1,
        {
            filter => \&_sprintf,
            value  => \@_,
        }
    );
}

#*****************************************************************************
#** @function public traced(@data)
# @brief Logging dump of structure of data in 'debug' level and with tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub traced {
    my (@data) = @_;

    return logger(
        'trace',
        1,
        {
            filter => \&_dumper,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public debug($message)
# @brief Logging scalar message in 'debug' level and without tracing calls
# @param $message   scalar, simple text
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub debug {
    my ($message) = @_;

    return logger( 'debug', 1, $message );
}

#*****************************************************************************
#** @function public debugf($format, @params)
# @brief Logging formatted message in 'debug' level and without tracing calls
# @param $format   scalar, message format
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub debugf {
    return logger(
        'debug',
        1,
        {
            filter => \&_sprintf,
            value  => \@_,
        }
    );
}

#*****************************************************************************
#** @function public debugd(@data)
# @brief Logging dump of structure of data in 'debug' level and without tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub debugd {
    my (@data) = @_;

    return logger(
        'debug',
        1,
        {
            filter => \&_dumper,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public debugdl(@data)
# @brief Logging one line dump of structure of data in 'debug' level and without tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub debugdl {
    my (@data) = @_;

    return logger(
        'debug',
        1,
        {
            filter => \&_dumper_line,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public info($message)
# @brief Logging scalar message in 'info' level and without tracing calls
# @param $message   scalar, simple text
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub info {
    my ($message) = @_;

    return logger( 'info', 1, $message );
}

#*****************************************************************************
#** @function public infof($format, @params)
# @brief Logging formatted message in 'info' level and without tracing calls
# @param $format   scalar, message format
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub infof {
    return logger(
        'info',
        1,
        {
            filter => \&_sprintf,
            value  => \@_,
        }
    );
}

#*****************************************************************************
#** @function public infod(@data)
# @brief Logging dump of structure of data in 'info' level and without tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub infod {
    my (@data) = @_;

    return logger(
        'info',
        1,
        {
            filter => \&_dumper,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public warning($message)
# @brief Logging scalar message in 'warning' level and without tracing calls
# @param $message   scalar, simple text
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub warning {
    my ($message) = @_;

    return logger( 'warn', 1, $message );
}

#*****************************************************************************
#** @function public warningf($format, @params)
# @brief Logging formatted message in 'warning' level and without tracing calls
# @param $format   scalar, message format
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub warningf {
    return logger(
        'warn',
        1,
        {
            filter => \&_sprintf,
            value  => \@_,
        }
    );
}

#*****************************************************************************
#** @function public warningd(@data)
# @brief Logging dump of structure of data in 'warning' level and without tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub warningd {
    my (@data) = @_;

    return logger(
        'warn',
        1,
        {
            filter => \&_dumper,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public error($message)
# @brief Logging scalar message in 'error' level and without tracing calls
# @param $message   scalar, simple text
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub error {
    my ($message) = @_;

    return logger( 'error', 1, $message );
}

#*****************************************************************************
#** @function public errorf($format, @params)
# @brief Logging formatted message in 'error' level and without tracing calls
# @param $format   scalar, message format
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub errorf {
    return logger(
        'error',
        1,
        {
            filter => \&_sprintf,
            value  => \@_,
        }
    );
}

#*****************************************************************************
#** @function public errord(@data)
# @brief Logging dump of structure of data in 'error' level and without tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub errord {
    my (@data) = @_;

    return logger(
        'error',
        1,
        {
            filter => \&_dumper,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public fatal($message)
# @brief Logging scalar message in 'fatal' level and without tracing calls
# @param $message   scalar, simple text
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub fatal {
    my ($message) = @_;

    return logger( 'logdie', 1, $message );
}

#*****************************************************************************
#** @function public fatalf($format, @params)
# @brief Logging formatted message in 'fatal' level and without tracing calls
# @param $format   scalar, message format
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub fatalf {
    return logger(
        'logdie',
        1,
        {
            filter => \&_sprintf,
            value  => \@_,
        }
    );
}

#*****************************************************************************
#** @function public fatald(@data)
# @brief Logging dump of structure of data in 'fatal' level and without tracing calls
# @param @data   structured data
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub fatald {
    my (@data) = @_;

    return logger(
        'logdie',
        1,
        {
            filter => \&_dumper,
            value  => \@data,
        }
    );
}

#*****************************************************************************
#** @function public logger($level, $depth, $message)
# @brief Logging scalar message in the pointed level
# @param $level     scalar, loglevel
# @param $depth     scalar, caller's depth
# @param $message   scalar, simple text
# @param @params   params for formatting
# @return scalar, integer - amount of the reached appenders; undef - If the message has been suppressed because of level constraints
#*
#-----------------------------------------------------------------------------
sub logger {
    my ( $level, $depth, $args ) = @_;

    $depth //= 1;
    my ( $package, $file, $line ) = caller $depth;

    my $is_level = 'is_' . ( ( $level eq 'logdie' ) ? 'fatal' : $level );
    my $logger = get_logger($package);
    if ( !$logger->$is_level() ) {
        return undef;
    }

    local $Log::Log4perl::caller_depth = ++$depth;

    return $logger->$level($args);
}

#*****************************************************************************
sub _flat {
    my ($args) = @_;

    return $args;
}

#*****************************************************************************
sub _sprintf {
    my ($args) = @_;

    return sprintf( shift( @{$args} ), @{ $args || [] } );
}

#*****************************************************************************
sub _dumper {
    my ($args) = @_;

    return dump_data( @{ $args || [] } );
}

#*****************************************************************************
sub _dumper_line {
    my ($args) = @_;

    my $data = dump_data( @{ $args || [] } );
    $data =~ s/\s+/ /gs;

    return $data;
}

#*****************************************************************************
init_logger( {
        'log4perl.logger'                                   => 'TRACE, SCREEN',
        'log4perl.appender.SCREEN'                          => 'Log::Log4perl::Appender::ScreenColoredLevels',
        'log4perl.appender.SCREEN.layout'                   => 'PatternLayout',
        'log4perl.appender.SCREEN.stderr'                   => '1',
        'log4perl.appender.SCREEN.layout.ConversionPattern' => '%d{ISO8601} [%P]: <%p> %M:%L - %m%n',
    }
);

#*****************************************************************************
1;
__END__
