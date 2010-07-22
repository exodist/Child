package Child;
use strict;
use warnings;
use Carp;

our $VERSION = "0.002";
our %META;

for my $reader ( qw/pid ipc exit code parent/ ) {
    my $prop = "_$reader";

    my $psub = sub {
        my $self = shift;
        ($self->{ $prop }) = @_ if @_;
        return $self->{ $prop };
    };

    my $rsub = sub {
        my $self = shift;
        return $self->$prop();
    };

    no strict 'refs';
    *$reader = $rsub;
    *$prop = $psub;
}

sub import {
    my $class = shift;
    my $caller = caller;
    my @import;
    for ( @_ ) {
        if ( m/^:(.+)$/ ) {
            $META{$caller}->{$1}++
        }
        else {
            no strict 'refs';
            *{"$caller\::$_"} = $class->can( $_ )
                || croak "'$_' is not exported by $class.";
        }
    }
    1;
}

sub child(&;@) {
    my ( $code, %params ) = @_;
    my $caller = caller;
    return __PACKAGE__->new($code, %{$META{$caller}}, %params )->start;
}

sub new {
    my ( $class, $code, %params ) = @_;
    my %proto = ( _code => $code );
    $proto{_ipc} = $class->_gen_ipc()
        if $params{pipe};
    return bless( \%proto, $class );
}

sub start {
    my $self = shift;
    my $parent = $$;
    if ( my $pid = fork() ) {
        $self->_pid( $pid );
        $self->_init_ipc if $self->ipc;
    }
    else {
        $self->_parent( $parent );
        $self->_init_ipc if $self->ipc;
        my $code = $self->code;
        $self->$code();
        exit;
    }
    return $self;
}

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
            $ret = waitpid( $self->pid, &POSIX::WNOHANG );
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

sub _gen_ipc {
    my $class = shift;
    # Only load if used;
    require IO::Pipe;
    return [
        IO::Pipe->new,
        IO::Pipe->new,
    ];
}

sub _init_ipc {
    my $self = shift;
    # Cross the pipes.
    if ( $self->parent ) {
        $self->_ipc([
            $self->_ipc->[1],
            $self->_ipc->[0],
        ]);
    }
    $self->_read_handle->reader;
    $self->_read_handle->autoflush(1);
    $self->_write_handle->writer;
    $self->_write_handle->autoflush(1);
}

sub _read_handle  {
    my $self = shift;
    $self->_no_pipe unless $self->_ipc;
    return $self->_ipc->[0];
}

sub _write_handle {
    my $self = shift;
    $self->_no_pipe unless $self->_ipc;
    return $self->_ipc->[1];
}

sub _no_pipe {
    croak(
        "Child was created without IPC support.",
        "To enable IPC construct the child with Child->new( sub { ... }, pipe => 1 )",
        "If you use child { ... }; then import Child with the ':pipe' argumunt",
        "use Child qw/child :pipe/",
    );
}

sub read {
    my $self = shift;
    my ( $block ) = @_;
    my $handle = $self->_read_handle;
    $handle->blocking( $block ? 1 : 0 );
    return <$handle>;
}

sub say {
    my $self = shift;
    $self->write( map {$_ . $/} @_ );
}

sub write {
    my $self = shift;
    my $handle = $self->_write_handle;
    print $handle @_;
}

1;

__END__

=head1 NAME

Child - Object oriented simple interface to fork()

=head1 DESCRIPTION

Fork is too low level, and difficult to manage. Often people forget to exit at
the end, reap their children, and check exit status. The problem is the low
level functions provided to do these things. Throw in pipes for IPC and you
just have a pile of things nobody wants to think about.

Child is an Object Oriented interface to fork. It provides a clean way to start
a child process, and manage it afterwords. It provides methods for running,
waiting, killing, checking, and even communicating with a child process.

=head1 SYNOPSIS

=head2 BASIC

    use Child;

    my $child = Child->new(sub {
        my $self = shift;
        ....
        # exit() is called for you at the end.
    });

    # Build with IPC
    my $child2 = Child->new(sub {
        my $self = shift;
        $self->say("message1");
        $self->say("message2");
        my $reply = $self->read(1);
    }, pipe => 1 );

    # Read (blocking)
    my $message1 = $child2->read(1);

    # Read (non-blocking)
    my $message2 = $child2->read();

    $child2->say("reply");

    # Kill the child if it is not done
    $child->complete || $child->kill(9);

    $child->wait; #blocking

=head2 SHORTCUT

Child can export the child(&) shortcut function when requested. This function
creates and starts the child process.

    use Child qw/child/;
    my $child = child {
        my $self = shift;
        ...
    };

You can also request IPC:

    use Child qw/child/;
    my $child = child {
        my $self = shift;
        ...
    } pipe => 1;

To add IPC to children created with child() by default, import with ':pipe'.
How child() behaves regarding IPC is lexical to each importing class.

    use Child qw/child :pipe/;

    my $child = child {
        my $self = shift;
        $self->say("message1");
    };

    my $message1 = $child->read(1);

=head1 METHODS

=over 4

=item $class->new( sub { ... } )

=item $class->new( sub { ... }, pipe => 1 )

Create a new Child object. Does not start the child.

=item $child->start()

Start the child process.

=item $bool = $child->is_complete()

Check if the child is finished (non-blocking)

=item $child->wait()

Wait on the child (blocking)

=item $child->kill($SIG)

Send the $SIG signal to the child process.

=item $child->read($BLOCK)

Read a message from the child. Takes a single boolean argument; when true the
method blocks.

=item $child->write( @MESSAGES )

Send the messages to the child. works like print, you must add "\n".

=item $child->say( @MESSAGES )

Send the messages to the child. works like say, adds the seperator for you
(usually "\n").

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

=back

=head1 HISTORY

Most of this was part of L<Parrallel::Runner> intended for use in the L<Fennec>
project. Fennec is being brocken into multiple parts, this is one such part.

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greator framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
