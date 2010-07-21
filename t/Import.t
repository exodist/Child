#!/usr/bin/perl;
use strict;
use warnings;

use Test::More;
our $CLASS = 'Child';
require_ok( $CLASS );

$CLASS->import();
ok( ! __PACKAGE__->can('child'), "No export by default" );

$CLASS->import('child');
can_ok( __PACKAGE__, 'child' );
my $one = child( sub { 1; });
ok( !$one->ipc, "no ipc by default" );

$CLASS->import(':pipe');
$one = child( sub { 1; });
ok( $one->ipc, "ipc added" );

done_testing;
