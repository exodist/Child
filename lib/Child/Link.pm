package Child::Link;
use strict;
use warnings;

use Child::Util;
use Carp qw/croak/;

add_accessors qw/pid/;

sub ipc { undef }

sub _no_ipc { croak "Child was created without IPC support" }

sub new {
    my $class = shift;
    my ( $pid ) = @_;
    return bless( { _pid => $pid }, $class );
}

{
    no strict 'refs';
    *{__PACKAGE__ . '::' . $_} = \&_no_ipc
        for qw/autoflush flush read say write/;
}

1;
