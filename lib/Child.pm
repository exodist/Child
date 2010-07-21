package Child;
use strict;
use warnings;
use Carp;

our $VERSION = "0.001";
our %META;

for my $reader ( qw/pid started ipc exit_status code parent/ ) {
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

sub child(&) {
    my ( $code ) = @_;
    my $caller = caller;
    return __PACKAGE__->new($code, %{$META{$caller}})->start;
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
    return defined($self->exit_status);
}

sub wait {
    my $self = shift;
    return unless $self->_wait(1);
    return !$self->exit_status;
}

sub _wait {
    my $self = shift;
    my ( $block ) = @_;
    unless ( defined $self->exit_status ) {
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
        $self->_exit_status( $? >> 8 );
    }
    return defined($self->exit_status);
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
