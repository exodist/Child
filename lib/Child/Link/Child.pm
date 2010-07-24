package Child::Link::Child;
use strict;
use warnings;

use Child::Util;

use base 'Child::Link';

add_accessors qw/exit/;

sub is_complete {
    my $self = shift;
    $self->_wait();
    return defined($self->exit);
}

sub wait {
    my $self = shift;
    return unless $self->_wait(1);
    return !$self->exit;
}

sub exit_status {
    my $self = shift;
    return unless $self->is_complete;
    return ($self->exit >> 8);
}

sub unix_exit {
    my $self = shift;
    return unless $self->is_complete;
    return $self->exit;
}

sub _wait {
    my $self = shift;
    my ( $block ) = @_;
    unless ( defined $self->exit ) {
        my @flags;
        require POSIX unless $block;
        my $ret;
        my $x = 1;
        do {
            sleep(1) if defined $ret;
            $ret = waitpid( $self->pid, $block ? 0 : &POSIX::WNOHANG );
        } while ( $block && !$ret );
        return 0 unless $ret;
        croak( "wait returned $ret: No such process " . $self->pid )
            if $ret < 0;
        $self->_exit( $? );
    }
    return defined($self->exit);
}

sub kill {
    my $self = shift;
    my ( $sig ) = @_;
    kill( $sig, $self->pid );
}

1;
