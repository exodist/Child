package Child::IPC::Pipe;
use strict;
use warnings;

use Child::Link::IPC::Pipe::Proc;
use Child::Link::IPC::Pipe::Parent;

use base 'Child';

sub child_class  { 'Child::Link::IPC::Pipe::Proc'   }
sub parent_class { 'Child::Link::IPC::Pipe::Parent' }

sub shared_data {
    pipe( my ( $ain, $aout ));
    pipe( my ( $bin, $bout ));
    return [
        [ $ain, $aout ],
        [ $bin, $bout ],
    ];
}

sub new {
    my ( $class, $code ) = @_;
    return bless( { _code => $code }, $class );
}

1;
