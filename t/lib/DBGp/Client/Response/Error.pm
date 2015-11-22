package DBGp::Client::Response::Error;

use strict;
use warnings;

sub transaction_id { $_[0]->[0]{transaction_id} }
sub command { $_[0]->[0]{command} }

sub code { $_[0]->[1]{attrib}{code} }
sub apperr { $_[0]->[1]{attrib}{apperr} }

sub message {
    return DBGp::Client::Parser::_text(
        DBGp::Client::Parser::_nodes($_[0]->[1], 'message')
    );
}

1;
