package Perl::Critic::Policy::ValuesAndExpressions::ProhibitSmartmatch;
# prohibit using ~~ because it's experimental and will be changed in future
# http://stackoverflow.com/questions/16927024/perl-5-20-and-the-fate-of-smart-matching-and-given-when

use strict;
use warnings;
use Readonly;
use Data::Dumper;

use Perl::Critic::Utils qw{ :severities $EMPTY };
use base 'Perl::Critic::Policy';

Readonly::Scalar my $DESC       => q{Using experimental features should be avoided};
Readonly::Scalar my $EXPL       => q{Consider using any() from List::MoreUtils};
Readonly::Scalar my $SMARTMATCH => q{~~};

sub default_severity { return $SEVERITY_HIGH }
sub default_themes   { return qw( porta ) }
sub applies_to       { return 'PPI::Document' }

# sub supported_parameters {
#     return ();
# }

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @ops = grep { $_->content eq $SMARTMATCH } @{ $doc->find('PPI::Token::Operator') || [] };

    my @violations = ();
    foreach my $op (@ops) {
        push @violations, $self->violation( $DESC, $EXPL, $op );
    }

    return @violations;
}

1;
