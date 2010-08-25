#!/usr/bin/perl
use 5.006;
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
        'Exporter' => 5.57,
        'perl' => 5.006,
    },
    build_requires => {
        'Test::More'      => 0.88,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/exodist/Child',
            bugtracker => 'http://github.com/exodist/Child/issues',
            homepage   => 'http://open-exodus.net/projects/child'
        },
    }
);

$build->create_build_script;
