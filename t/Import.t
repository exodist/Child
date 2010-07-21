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

