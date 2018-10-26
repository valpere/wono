package Wono::Driver::Tomcat8;

use utf8;

use Mouse;

extends 'Wono::Driver';

use LWP::UserAgent;
use HTTP::Request::Common ();
use HTTP::Request;
use HTTP::Status qw(:constants);
use URI;
use MIME::Base64 qw(encode_base64);
use Ref::Util qw(
    is_arrayref
);

# search for libs in module's directory
use FindBin qw($Bin);
use lib( $Bin, "$Bin/../.." );

use Wono::Logger qw(
    debugd
    debugf
    fatalf
);

#*****************************************************************************
has 'ua' => (
    is      => 'ro',
    isa     => 'Object',
    builder => '_get_ua',
);

has 'proxy' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'username' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'password' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'basic_auth' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_get_basic_auth',
    init_arg => undef,
);

has 'timeout' => (
    is      => 'rw',
    isa     => 'Maybe[Int]',
    default => undef,
);

#***********************************************************************
sub _get_ua {
    my ($self) = @_;

    local $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}    = 0;            # avoid certificate verification
    local $ENV{HTTPS_DEBUG}                     = 0;

    my $ua = LWP::UserAgent->new(
        ssl_opts => {
            verify_hostname => 0,
        },
    );

    return $ua;
}

#**************************************************************************
sub session_close {
    my ($self) = @_;

    return undef;
}

#*****************************************************************************
sub call {
    my ( $self, $args ) = @_;

    if ( $self->timeout ) {
        $self->ua->timeout( $self->timeout );
    }

    my ( $method, $action, $params, $attachments ) = @{$args}{qw(method action params attachments)};

    my $uri = URI->new( $self->proxy );
    $uri->path($action);
    if ($params) {
        $uri->query_form($params);
    }

    my $url = $uri->as_string;
    if ( $self->verbose_verbose ) {
        debugf( 'URL: %s', $url );
    }

    my $upload;
    if ($attachments) {
        if ( !is_arrayref($attachments) ) {
            $attachments = [$attachments];
        }

        foreach my $attachment ( @{$attachments} ) {
            push( @{$upload}, ( upload_file => [$attachment] ) );
        }
    }

    $method = HTTP::Request::Common->can($method);
    my $request = $method->(
        $url,
        Authorization => $self->basic_auth,
        $upload ? ( 'Content_Type' => 'form-data' ) : (),
        $upload ? ( Content        => $upload )     : (),
    );

    if ( $self->verbose_verbose ) {
        debugd( 'request: ', $request->as_string );
    }

    my $response = $self->ua->request($request);

    if ( $self->verbose_verbose ) {
        debugd( 'response: ', $response->as_string );
    }

    if ( !$response->is_success() ) {
        die( sprintf( 'Exception: %s, Description: %s', $response->code, $response->status_line ) . "\n" );
    }

    if ( $response->code == HTTP_NO_CONTENT ) {
        $response = '';
    }
    else {
        $response = $response->decoded_content;
    }

    return $response;
} ## end sub call

#*****************************************************************************
sub _get_basic_auth {
    my ($self) = @_;

    return sprintf( 'Basic %s', encode_base64( sprintf( '%s:%s', $self->username, $self->password ), '' ) );
}

#*****************************************************************************
no Mouse;
__PACKAGE__->meta->make_immutable;
#*****************************************************************************
1;
__END__
