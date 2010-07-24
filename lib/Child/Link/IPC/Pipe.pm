package Child::Link::IPC::Pipe;
use strict;
use warnings;

use Child::Util;

use base 'Child::Link::IPC';

add_abstract qw/cross_pipes/;

sub read_handle  { shift->ipc->[0] }
sub write_handle { shift->ipc->[1] }

sub init {
    my $self = shift;
    my ($pipes) = @_;

    $pipes = [
        $pipes->[1],
        $pipes->[0],
    ] if $self->cross_pipes;

    $self->_ipc([
        $pipes->[0]->[0],
        $pipes->[1]->[1],
    ]);
    $self->autoflush(1);
}

1;
