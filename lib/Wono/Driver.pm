package Wono::Driver;

use utf8;

use Mouse;

# search for libs in module's directory
use FindBin qw($Bin);
use lib( $Bin, "$Bin/.." );

use Wono::Constants qw(
    $SLEEP_BEFORE_RECONNECT
);
use Wono::Logger qw(
    debugd
    fatalf
);

#*****************************************************************************
has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    builder  => '_build_name',
    init_arg => undef,
);

has 'verbose' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'verbose_verbose' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

#*****************************************************************************
sub this {
    my ($self) = @_;

    my $this = ( caller(1) )[3];
    $this =~ s/^.*:://;

    return $this;
}

#*****************************************************************************
sub session_open {
    my ($self) = @_;

    return 0;
}

#*****************************************************************************
sub session_close {
    my ($self) = @_;

    return 0;
}

#*****************************************************************************
sub reconnect {
    my ( $self, $retry ) = @_;

    if ( !$self->session_close ) {
        return 0;
    }

    if ($retry) {
        sleep( $SLEEP_BEFORE_RECONNECT * $retry );
    }

    return $self->session_open;
}

#*****************************************************************************
sub call {
    my ( $self, $args ) = @_;

    return fatalf( q{Method '%s' for '%s' is not implemented yet}, $self->this, $self->name );
}

#*****************************************************************************
sub _build_name {
    my ($self) = @_;

    my ($name) = ( ref($self) || $self ) =~ /::(\w+)$/i;

    return lc( $name // '' );
}

#*****************************************************************************
no Mouse;
__PACKAGE__->meta->make_immutable;
#*****************************************************************************
1;
__END__
