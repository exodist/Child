#!/usr/bin/perl;
use strict;
use warnings;

use Test::More 0.88;
use Capture::Tiny qw(capture_stderr);
our $CLASS = 'Child';

require_ok( $CLASS );

note "die in child"; {
    my $pid = $$;

    is capture_stderr {
        my $child = Child->new(sub { die "Foo\n" });
        my $proc = $child->start;
        $proc->wait;
    }, "Foo\n";

    is $pid, $$, "didn't leak out of the child process";
}

note "Child in eval"; {
    my $pid = $$;

    is capture_stderr {
        eval {
            my $child = Child->new(sub { die "Foo\n" });
            my $proc = $child->start;
            $proc->wait;
        };
        is $@, '', "child death does not affect parent \$@";
    }, "Foo\n";

    is $pid, $$, "didn't leak out of the child process";
};

done_testing;
