package DBGp::Client::Parser;

use strict;
use warnings;

use XML::Parser;
use XML::Parser::EasyTree;

use DBGp::Client::Response::Init;
use DBGp::Client::Response::Error;
use DBGp::Client::Response::Step;
use DBGp::Client::Response::StackGet;
use DBGp::Client::Response::Eval;
use DBGp::Client::Response::Typemap;
use DBGp::Client::Response::ContextGet;

my $parser = XML::Parser->new(Style => 'EasyTree');

sub _nodes {
    my ($nodes, $node) = @_;

    return grep $_->{type} eq 'e' && $_->{name} eq $node, @{$nodes->{content}};
}

sub _node {
    my ($nodes, $node) = @_;

    return (_nodes($nodes, $node))[0];
}

sub _text {
    my ($nodes) = @_;
    my $text = '';

    for my $node (@{$nodes->{content}}) {
        $text .= $node->{content}
            if $node->{type} eq 't';
    }

    return $text;
}

sub parse {
    return undef unless defined $_[0];

    my $tree = $parser->parse($_[0]);
    die "Unexpected XML"
        if @$tree != 1 || $tree->[0]{type} ne 'e';

    my $root = $tree->[0];
    if ($root->{name} eq 'init') {
        return bless $root->{attrib}, 'DBGp::Client::Response::Init';
    } elsif ($root->{name} eq 'response') {
        if (ref $root->{content} && (my $error = _node($root, 'error'))) {
            return bless [$root->{attrib}, $error], 'DBGp::Client::Response::Error';
        }

        my $cmd = $root->{attrib}{command};

        if ($cmd eq 'step_into' || $cmd eq 'step_over' || $cmd eq 'run' ||
                $cmd eq 'step_out' || $cmd eq 'detach' || $cmd eq 'stop') {
            return bless $root, 'DBGp::Client::Response::Step';
        } elsif ($cmd eq 'stack_get') {
            return bless $root, 'DBGp::Client::Response::StackGet';
        } elsif ($cmd eq 'eval') {
            return bless $root, 'DBGp::Client::Response::Eval';
        } elsif ($cmd eq 'typemap_get') {
            return bless $root, 'DBGp::Client::Response::Typemap';
        } elsif ($cmd eq 'context_get') {
            return bless $root, 'DBGp::Client::Response::ContextGet';
        } else {
            require Data::Dumper;

            die "Unknown command '$cmd' " . Data::Dumper::Dumper($root);
        }
    } else {
        require Data::Dumper;

        die "Unknown response '$root' " . Data::Dumper::Dumper($root);
    }
}

1;
