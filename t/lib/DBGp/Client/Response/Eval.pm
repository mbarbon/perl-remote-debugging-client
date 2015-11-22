package DBGp::Client::Response::Eval;

use strict;
use warnings;

use DBGp::Client::Response::Property;

sub transaction_id { $_[0]->{attrib}{transaction_id} }
sub command        { $_[0]->{attrib}{command} }

sub result {
    return bless DBGp::Client::Parser::_node($_[0], 'property'),
                 'DBGp::Client::Response::Property';
}

1;
