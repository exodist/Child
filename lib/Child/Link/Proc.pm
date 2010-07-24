package Child::Link::Proc;
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
=item $bool = $child->is_complete()

Check if the child is finished (non-blocking)

=item $child->wait()

Wait on the child (blocking)

=item $child->kill($SIG)

Send the $SIG signal to the child process.

=item $child->read()

Read a message from the child.

=item $child->write( @MESSAGES )

Send the messages to the child. works like print, you must add "\n".

=item $child->say( @MESSAGES )

Send the messages to the child. works like say, adds the seperator for you
(usually "\n").

=item $child->autoflush( $BOOL )

Turn autoflush on/off for the current processes write handle. This is on by
default.

=item $child->flush()

Flush the current processes write handle.

=item $child->pid()

Returns the child PID (only in parent process).

=item $child->exit_status()

Will be undef unless the process has exited, otherwise it will have the exit
status.

B<Note>: When you call exit($N) the actual unix exit status will be bit shifed
with extra information added. exit_status() will shift the value back for you.
That means exit_status() will return 2 whun your child calls exit(2) see
unix_exit() if you want the actual value wait() assigned to $?.

=item $child->unix_exit()

When you call exit($N) the actual unix exit status will be bit shifed
with extra information added. See exit_status() if you want the actual value
used in exit() in the child.

=item $child->code()

Returns the coderef used to construct the Child.

=item $child->parent()

Returns the parent processes PID. (Only in child)

=item $child->detach()

Detach the child from the parent. uses POSIX::setsid(). When called in the
child it simply calls setsid. When called from the parent the USR1 signal is
sent to the child which triggers the child to call setsid.


