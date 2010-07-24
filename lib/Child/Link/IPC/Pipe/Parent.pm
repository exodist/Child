package Child::Link::IPC::Pipe::Parent;
use strict;
use warnings;

use Child::Util;

use base qw/
    Child::Link::IPC::Pipe
    Child::Link::Parent
/;

sub cross_pipes { 1 };

1;
