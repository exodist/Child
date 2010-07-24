package Child::Util;
use strict;
use warnings;
use Carp qw/croak/;

use base 'Exporter';
our @EXPORT = qw/add_accessors add_abstract/;

sub _abstract {
    my $class = shift;
    croak "$class does not implement this function."
}

sub add_abstract {
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::$_"} = \&_abstract for @_;
}

sub add_accessors {
    my $class = caller;
    _add_accessor( $class, $_ ) for @_;
}

sub _add_accessor {
    my ( $class, $reader ) = @_;
    my $prop = "_$reader";

    my $psub = sub {
        my $self = shift;
        ($self->{ $prop }) = @_ if @_;
        return $self->{ $prop };
    };

    my $rsub = sub {
        my $self = shift;
        return $self->$prop();
    };

    no strict 'refs';
    *{"$class\::$reader"} = $rsub;
    *{"$class\::$prop"} = $psub;
}

1;
