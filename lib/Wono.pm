package Wono;

use utf8;

our $VERSION = 0.010;

use Mouse;

use Pod::Usage;
use Getopt::Long;
use Const::Fast;
use English qw(-no_match_vars);
use Hash::Merge ();
use File::Spec  ();
use File::Path qw(make_path);
use File::Basename ();
use Digest::MD5 qw(md5_hex);

# search for libs in module's directory
use FindBin qw(
    $Bin
    $Script
);
use lib($Bin);

use Wono::Constants qw(
    $SIGNAL_DIE
    $SIGNAL_WARN
);
use Wono::Utils qw(
    json_load
    strip_spaces
);
use Wono::Logger qw(
    init_logger
    logger
    debugd
    info
    infof
    fatalf
);

#*****************************************************************************
const my $_OPTIONS => [
    # -- shared ------------
    'help|h|?',
    'man',
    'config|c=s',
    'data_dir|d=s',
    'verbose|v',
    'verbose_verbose|vv',
];

const my $_META_NAME => 'metadata';

#*****************************************************************************
has 'basename' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_basename',
    init_arg => undef,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_name',
    init_arg => undef,
);

has 'to_finalize' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has 'in_request' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'params' => (
    is  => 'rw',
    isa => 'HashRef',
);

has 'data_dir' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_data_dir',
    init_arg => undef,
);

has 'verbose' => (
    is       => 'ro',
    isa      => 'Bool',
    lazy     => 1,
    builder  => '_get_verbose',
    init_arg => undef,
);

has 'verbose_verbose' => (
    is       => 'ro',
    isa      => 'Bool',
    lazy     => 1,
    builder  => '_get_verbose_verbose',
    init_arg => undef,
);

#*****************************************************************************
sub run {
    my ( $self, $params, $opts ) = @_;

    $self->initialize( $params, $opts );
    debugd( { config => $self->params, } );
    infof('Initialize done');

    local $SIG{TERM}         = sub { $self->on_term(@_); };
    local $SIG{INT}          = sub { $self->on_term(@_); };
    local $SIG{$SIGNAL_DIE}  = sub { $self->on_die(@_); };
    local $SIG{$SIGNAL_WARN} = sub { $self->on_warn(@_); };

    $self->in_request(1);
    my $ret = $self->process_init;
    $self->in_request(0);

    if ( !$ret || $self->to_finalize() ) {
        $self->finalize();
    }

    while (1) {
        $self->in_request(1);
        $ret = $self->process_iteration;
        $self->in_request(0);

        if ( !$ret || $self->to_finalize ) {
            last;
        }
    }

    $self->in_request(1);
    $self->process_done;
    $self->in_request(0);

    $self->finalize();

    return undef;
} ## end sub run

#*****************************************************************************
sub on_term {
    my ( $self, $sig ) = @_;

    infof( '%s: %s', $sig, $OS_ERROR );

    if ( $self->in_request() ) {
        $self->to_finalize($sig);
    }
    else {
        $self->finalize($sig);
    }

    return undef;
}

#*****************************************************************************
sub save_state {
    my ($self) = @_;

    return 1;
}

#*****************************************************************************
sub on_die {
    my ( $self, @params ) = @_;

    if ( !$EXCEPTIONS_BEING_CAUGHT ) {
        # we are not inside eval
        # to avoid ERROR: Can't locate object method "tid" via package "threads" at /usr/share/perl5/XSLoader.pm
        logger( 'error', 2, join( " ", @params ) );
        $self->save_state();
    }

    return undef;
}

#*****************************************************************************
sub on_warn {
    my ( $self, @params ) = @_;

    if ( !$EXCEPTIONS_BEING_CAUGHT ) {
        # we are not inside eval
        # to avoid ERROR: Can't locate object method "tid" via package "threads" at /usr/share/perl5/XSLoader.pm
        logger( 'info', 2, join( ' ', @params ) );
    }

    return undef;
}

#*****************************************************************************
sub finalize {
    my ( $self, $msg ) = @_;

    $self->save_state();

    $msg ||= $self->to_finalize || 'SUCCESS';

    info($msg);

    exit(0);
}

#*****************************************************************************
sub process_init {
    my ($self) = @_;

    return 1;
}

#*****************************************************************************
sub process_iteration {
    my ($self) = @_;

    return undef;
}

#*****************************************************************************
sub process_done {
    my ($self) = @_;

    return 1;
}

#*****************************************************************************
sub initialize {
    my ( $self, $preps, $opts ) = @_;

    $opts  //= [];
    $preps //= {};

    my $params = {};
    if ( !GetOptions( $params, @{$opts}, @{$_OPTIONS} ) ) {
        pod2usage( -verbose => 0, -exitval => 2, -output => \*STDERR, -message => "Invalid option(s)" );
    }

    if ( $params->{help} ) {
        pod2usage( -verbose => 0, -exitval => 2, -output => \*STDERR );
    }

    if ( $params->{man} ) {
        pod2usage( -verbose => 1, -exitval => 2, -output => \*STDERR );
    }

    my $basename    = $self->basename;
    my $config_name = $self->name;

    my $config_file = $params->{config};
    if ( !$config_file ) {
        $config_file = File::Spec->catfile( File::Spec->curdir, $config_name . '.conf' );
        if ( !-e $config_file ) {
            $config_file = File::Spec->catfile( $Bin, '..', 'etc', $config_name . '.conf' );
        }
    }

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    $merge->set_clone_behavior(1);
    $self->params( $merge->merge( $merge->merge( $preps, ( json_load($config_file) // {} ) ), $params ) );

    $params = $self->params;

    if ( !defined( $params->{data_dir} ) || ( $params->{data_dir} eq '' ) ) {
        pod2usage( -verbose => 0, -exitval => 1, -output => \*STDERR, -message => "Undefined data directory" );
    }

    my $data_dir = $self->data_dir;

    if ( $params->{logger} ) {
        $params->{logger}->{'log4perl.appender.LOGFILE.filename'} = File::Spec->catfile( $data_dir, $basename . '.log' );
        init_logger( $params->{logger} );
    }

    return undef;
} ## end sub initialize

#*****************************************************************************
sub this {
    my ($self) = @_;

    my $this = ( caller(1) )[3];
    $this =~ s/^.*:://;

    return $this;
}

#*****************************************************************************
sub _build_basename {
    my ($self) = @_;

    return lc( File::Basename::basename( $Script, '.pl' ) );
}

#*****************************************************************************
sub _build_name {
    my ($self) = @_;

    return $self->basename;
}

#*****************************************************************************
sub _build_data_dir {
    my ($self) = @_;

    my $data_dir = $self->params->{data_dir};

    make_path($data_dir);

    printf( "Data dir: %s\n", $data_dir );

    return $data_dir;
}

#*****************************************************************************
sub _get_verbose {
    my ($self) = @_;

    return $self->params->{verbose} || $self->params->{verbose_verbose};
}

#*****************************************************************************
sub _get_verbose_verbose {
    my ($self) = @_;

    return $self->params->{verbose_verbose};
}

#*****************************************************************************
no Mouse;
__PACKAGE__->meta->make_immutable;
#*****************************************************************************
1;
__END__
