package t::lib::Test;

use 5.006;
use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;

BEGIN {
    my @prereqs = qw(Test::Differences XML::Parser XML::Parser::EasyTree);
    my %failed;

    for my $prereq (@prereqs) {
        $failed{$prereq} = $@ unless eval "require $prereq; 1";
    }

    if (%failed) {
        note $_ for values %failed;
        plan skip_all => 'Some dependencies failed: ' . join(" ", keys %failed);
    }
}

use Test::Differences;

use IO::Socket::INET;
use IPC::Open3 ();
use MIME::Base64 qw(encode_base64);
use Cwd;

require feature;

our @EXPORT = (
  @Test::More::EXPORT,
  @Test::Differences::EXPORT,
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
    feature->import(':5.12');

    goto &Test::Builder::Module::import;
}

my ($LISTEN, $CLIENT, $INIT, $SEQ, $PORT);
my ($PID, $CHILD_IN, $CHILD_OUT, $CHILD_ERR);

sub abs_uri {
    return 'file://' . Cwd::abs_path($_[0]);
}

sub start_listening {
    return if $LISTEN;

    for my $port (!$PORT ? (17000 .. 19000) : ($PORT)) {
        $LISTEN = IO::Socket::INET->new(
            Listen    => 1,
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            Timeout   => 2,
        );
        next unless $LISTEN;

        $PORT = $port;
        last;
    }

    die "Unable to open a listening socket in the 17000 - 19000 port range"
        unless $LISTEN;
}

sub stop_listening {
    close $LISTEN;
    $LISTEN = undef;
}

sub run_program {
    my ($script, $opts) = @_;
    $opts ||= '';

    local $ENV{PERLDB_OPTS} = "RemotePort=localhost:$PORT $opts";
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

sub wait_connection {
    my ($reject) = @_;
    my $conn = $LISTEN->accept;

    die "Did not receive any connection from the debugged program: ", $LISTEN->error
        unless $conn;

    if ($reject) {
        close $conn;
        return;
    }

    require DBGp::Client::Stream;
    require DBGp::Client::Parser;

    $CLIENT = DBGp::Client::Stream->new(socket => $conn);

    # consume initialization line
    $INIT = DBGp::Client::Parser::parse($CLIENT->get_line);

    die "We got connected with the wrong debugged program"
        if $INIT->appid != $PID || $INIT->language ne 'Perl';
}

sub wait_line {
    readline $CHILD_OUT;
}

sub send_line {
    print $CHILD_IN "\n";
    flush $CHILD_IN;
}

sub send_command {
    my ($command, @args) = @_;

    $CLIENT->put_line($command, '-i', ++$SEQ, @args);
    my $res = DBGp::Client::Parser::parse($CLIENT->get_line);

    die 'Mismatched transaction IDs: got ', $res->transaction_id,
            ' expected ', $SEQ
        if $res && $res->transaction_id != $SEQ;

    return $res;
}

sub command_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($command, $expected) = @_;
    my $res = send_command(@$command);
    my $cmp = _extract_command_data($res, $expected);

    eq_or_diff($cmp, $expected);
}

sub eval_value_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($expr, $value) = @_;
    my $res = send_command('eval', encode_base64($expr));

    is($res->result->value, $value);
}

sub _extract_command_data {
    my ($res, $expected) = @_;

    if (!ref $expected) {
        return $res;
    } elsif (ref $expected eq 'HASH') {
        return {
            map {
                $_ => _extract_command_data($res->$_, $expected->{$_})
            } keys %$expected
        };
    } elsif (ref $expected eq 'ARRAY') {
        return $res if ref $res ne 'ARRAY';
        return [
            map {
                $_ > $#$expected ? '<extra element in response>' :
                $_ > $#$res      ? '<missing element in response>' :
                    _extract_command_data($res->[$_], $expected->[$_])
            } 0 .. ($#$expected > $#$res ? $#$expected : $#$res)
        ];
    } else {
        die "Can't extract ", ref $expected, "value";
    }
}

sub _cleanup {
    return unless $PID;
    kill 9, $PID;
}

END { _cleanup() }

1;
