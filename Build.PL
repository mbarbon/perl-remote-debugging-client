#!/usr/bin/perl

use strict;
use warnings;

use lib 'inc';
use Module::Build::DBGp;

my $build = Module::Build::DBGp->new(
    module_name     => 'Devel::Debug::DBGp',
    dist_version    => '0.01',
    dist_author     => 'Mattia Barbon <mbarbon@cpan.org>',
    dist_abstract   => 'Perl DBGp debugger (derived from Komodo remote debugging helper)',
    debugger_files  => ['perl5db.pl'],
    license         => 'artistic',
    configure_requires => {
        'Module::Build'  => 0.42,
    },
    test_requires => {
        'Test::Differences'         => 0,
        'XML::Parser'               => 0,
        'XML::Parser::EasyTree'     => 0,
    },
);
$build->add_build_element('debugger');
$build->create_build_script;
