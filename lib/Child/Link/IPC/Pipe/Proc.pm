package Child::Link::IPC::Pipe::Proc;
use strict;
use warnings;

use Child::Util;

use base qw/
    Child::Link::IPC::Pipe
    Child::Link::Proc
/;

sub cross_pipes { 0 };

1;
