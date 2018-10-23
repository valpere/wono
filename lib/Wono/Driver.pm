package Wono::Driver;

use utf8;

use Mouse;

# search for libs in module's directory
use FindBin qw($Bin);
use lib( $Bin, "$Bin/.." );

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

#*****************************************************************************
sub session_open {
    my ($self) = @_;

    return 1;
}

#*****************************************************************************
sub session_close {
    my ($self) = @_;

    return 1;
}

#*****************************************************************************
sub call {
    my ( $self, $args ) = @_;

    return fatalf( q{Method '%s' for '%s' is not implemented yet}, $self->this, $self->name );
}

#*****************************************************************************
sub this {
    my ($self) = @_;

    my $this = ( caller(1) )[3];
    $this =~ s/^.*:://;

    return $this;
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
