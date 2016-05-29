#!/usr/bin/perl

use t::lib::Test;

$ENV{DBGP_PERL_IGNORE_PADWALKER} = 1;

run_debugger('t/scripts/variables.pl', 'Xdebug=nested_properties_in_context');

send_command('run');

command_is(['context_get'], {
    command => 'context_get',
    values  => [
        {
            name        => '$foo',
            fullname    => '$foo',
            type        => 'int',
            constant    => '0',
            children    => '0',
            value       => '123',
        },
        {
            name        => '%foo',
            fullname    => '%foo',
            type        => 'HASH',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            value       => undef,
            childs      => [
                {
                    name        => '{a}',
                    fullname    => '$foo{a}',
                    type        => 'int',
                    constant    => '0',
                    children    => '0',
                    value       => '1',
                },
                {
                    name        => '{b}',
                    fullname    => '$foo{b}',
                    type        => 'int',
                    constant    => '0',
                    children    => '0',
                    value       => '2',
                },
                {
                    name        => '{c}',
                    fullname    => '$foo{c}',
                    type        => 'int',
                    constant    => '0',
                    children    => '0',
                    value       => '3',
                },
            ],
        },
        {
            name        => '@foo',
            fullname    => '@foo',
            type        => 'ARRAY',
            constant    => '0',
            children    => '1',
            numchildren => '3',
            value       => undef,
            childs      => [
                {
                    name        => '[0]',
                    fullname    => '$foo[0]',
                    type        => 'int',
                    constant    => '0',
                    children    => '0',
                    value       => '1',
                },
                {
                    name        => '[1]',
                    fullname    => '$foo[1]',
                    type        => 'int',
                    constant    => '0',
                    children    => '0',
                    value       => '2',
                },
                {
                    name        => '[2]',
                    fullname    => '$foo[2]',
                    type        => 'int',
                    constant    => '0',
                    children    => '0',
                    value       => '3',
                },
            ],
        },
    ],
});

done_testing();
