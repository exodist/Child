package Child::Link::Parent;
use strict;
use warnings;

use Child::Util;

use base 'Child::Link';

add_accessors qw/detached/;

sub detach {
    my $self = shift;
    require POSIX;
    $self->_detached( POSIX::setsid() )
        || die "Cannot detach from parent $!";
}

1;
