package Perl::Critic::Policy::ValuesAndExpressions::ProhibitQuotedHashKey;
# prohibit using $hash->{'value'}, use $hash->{value}

use strict;
use warnings;
use Readonly;
use Data::Dumper;

use Perl::Critic::Utils qw{ :severities $EMPTY };
use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC => q{Quoted hash key};
Readonly::Scalar my $EXPL => 'Use $hash->{key} syntax';

sub default_severity { return $SEVERITY_HIGH }
sub default_themes   { return qw( porta ) }
sub applies_to       { return 'PPI::Document' }

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Both [...] and {...} parts
    my $subscripts = $doc->find('PPI::Structure::Subscript');
    return () if ( !$subscripts );

    my @violations = ();

    foreach my $subs ( @{$subscripts} ) {

        next if ( $subs->children > 1 );

        my $quotes = $subs->find('PPI::Token::Quote');
        next if ( !$quotes );

        foreach my $quote ( @{$quotes} ) {
            # what is the inside
            my $string = $quote->string;

            if ( $string =~ /^[a-z_]\w*$/i ) {
                # such keys can be safely unquoted
                push @violations, $self->violation( $DESC, $EXPL, $subs );
                last;
            }
        }
    }

    return @violations;
} ## end sub violates

1;
