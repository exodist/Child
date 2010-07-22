#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Child',
    license     => 'perl',
    dist_author => 'Chad Granum <exodist7@gmail.com>',
    create_readme => 1,
    requires => {
        'POSIX'    => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/Child',
            bugtracker => 'http://github.com/exodist/Child/issues',
        },
    }
);

$build->create_build_script;
