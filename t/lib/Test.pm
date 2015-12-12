package t::lib::Test;

use 5.006;
use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;
use Test::DBGp;

use IPC::Open3 ();
use MIME::Base64 qw(encode_base64);
use Cwd;
use File::Spec::Functions;

our @EXPORT = (
  @Test::More::EXPORT,
  @Test::DBGp::EXPORT,
  qw(
        abs_uri
        run_debugger
        run_program
        send_command
        command_is
        eval_value_is
        start_listening
        stop_listening
        wait_connection
        close_connection
        wait_line
        send_line
  )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

my ($PID, $CHILD_IN, $CHILD_OUT, $CHILD_ERR);

sub abs_uri {
    return 'file://' . File::Spec::Functions::rel2abs(
        $_[0], Cwd::getcwd());
}

sub start_listening { dbgp_listen() }
sub stop_listening { dbgp_stop_listening() }

sub run_program {
    my ($script, $opts) = @_;
    $opts ||= '';

    my $port = dbgp_listening_port();
    local $ENV{PERLDB_OPTS} = "RemotePort=localhost:$port $opts";
    local $ENV{PERL5LIB} = $ENV{PERL5LIB} ? ".:$ENV{PERL5LIB}" : ".";
    $PID = IPC::Open3::open3(
        $CHILD_IN, $CHILD_OUT, $CHILD_ERR,
        $^X, '-d', $script,
    );
}

sub run_debugger {
    my ($script, $opts) = @_;

    start_listening();
    run_program($script, $opts);
    wait_connection();
}

sub wait_connection { dbgp_wait_connection($PID, @_) }

sub wait_line {
    readline $CHILD_OUT;
}

sub send_line {
    print $CHILD_IN "\n";
    flush $CHILD_IN;
}

sub send_command { dbgp_send_command(@_) }

sub command_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    dbgp_command_is(@_);
}

sub eval_value_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($expr, $value) = @_;
    my $res = send_command('eval', encode_base64($expr));

    is($res->result->value, $value);
}

sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
