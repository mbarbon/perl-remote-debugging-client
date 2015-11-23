#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/base.pl', 'Xdebug=1');

command_is(['eval', encode_base64('$i')], {
    command => 'eval',
    result  => {
        name        => '$i',
        fullname    => '$i',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => undef,
    },
});

command_is(['eval', encode_base64('"a"')], {
    command => 'eval',
    result  => {
        name        => '"a"',
        fullname    => '"a"',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => 'a',
    },
});

command_is(['eval', encode_base64('$i + 0')], {
    command => 'eval',
    result  => {
        name        => '$i + 0',
        fullname    => '$i + 0',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '0',
    },
});

done_testing();
