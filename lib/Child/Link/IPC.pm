package Child::Link::IPC;
use strict;
use warnings;

use Child::Util;

use base 'Child::Link';

add_accessors qw/ipc/;
add_abstract qw/
    read_handle
    write_handle
    init
/;

sub new {
    my $class = shift;
    my ( $pid, @shared ) = @_;
    my $self = $class->SUPER::new($pid);
    $self->init( @shared );
    return $self;
}

sub autoflush {
    my $self = shift;
    my ( $value ) = @_;
    my $write = $self->write_handle;

    my $selected = select( $write );
    $| = $value if @_;
    my $out = $|;

    select( $selected );

    return $out;
}

sub flush {
    my $self = shift;
    my $orig = $self->autoflush();
    $self->autoflush(1);
    my $write = $self->write_handle;
    $self->autoflush($orig);
}

sub read {
    my $self = shift;
    my $handle = $self->read_handle;
    return <$handle>;
}

sub say {
    my $self = shift;
    $self->write( map {$_ . $/} @_ );
}

sub write {
    my $self = shift;
    my $handle = $self->write_handle;
    print $handle @_;
}

1;
