package Child::Link::IPC::Pipe::Child;
use strict;
use warnings;

use Child::Util;

use base qw/
    Child::Link::IPC::Pipe
    Child::Link::Child
/;

sub cross_pipes { 0 };

1;
