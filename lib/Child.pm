package Child;
use strict;
use warnings;
use Carp;
use Child::Util;
use Child::Link::Child;
use Child::Link::Parent;

use base 'Exporter';

our $VERSION = "0.007";
our @CHILDREN;
our @EXPORT_OK = qw/child/;

add_accessors qw/code/;

sub child(&;@) {
    my ( $code, @params ) = @_;
    my $caller = caller;
    return __PACKAGE__->new( $code, @params )->start;
}

sub all_children { @CHILDREN }

sub all_child_pids {
    my $class = shift;
    map { $_->pid } $class->all_children;
}

sub wait_all {
    my $class = shift;
    $_->wait() for $class->all_children;
}

sub new {
    my ( $class, $code, $plugin, @data ) = @_;

    return bless( { _code => $code }, $class )
        unless $plugin;

    my $build = __PACKAGE__;
    $build .= '::IPC::' . ucfirst $plugin;

    eval "require $build; 1"
        || croak( "Could not load plugin '$plugin': $@" );

    return $build->new( $code, @data );
}

sub shared_data {}

sub child_class  { 'Child::Link::Child'  }
sub parent_class { 'Child::Link::Parent' }

sub start {
    my $self = shift;
    my $ppid = $$;
    my @data = $self->shared_data;

    if ( my $pid = fork() ) {
        my $proc = $self->child_class->new( $pid, @data );
        push @CHILDREN => $proc;
        return $proc;
    }

    # In the child
    @CHILDREN = ();
    my $parent = $self->parent_class->new( $ppid, @data );
    my $code = $self->code;
    $code->( $parent );
    exit;
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
    my $message1 = $child2->read();
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

    my $message1 = $child->read();

=head1 CLASS METHODS

=over 4

=item @children = Child->all_children()

Get a list of all the children that have been started. This list is cleared in
children when they are started.

=item @pids = Child->all_child_pids()

Get a list of all the pids of children that have been started.

=item Child->wait_all()

Call wait() on all children.

=back

=head1 CONSTRUCTOR

=over 4

=item $class->new( sub { ... } )

=item $class->new( sub { ... }, pipe => 1 )

Create a new Child object. Does not start the child.

=back

=head1 OBJECT METHODS

=over

=item $child->start()

Start the child process.

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

=back

=head1 HISTORY

Most of this was part of L<Parrallel::Runner> intended for use in the L<Fennec>
project. Fennec is being broken into multiple parts, this is one such part.

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
