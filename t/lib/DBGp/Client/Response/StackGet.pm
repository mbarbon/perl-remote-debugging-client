package DBGp::Client::Response::StackGet;

use strict;
use warnings;

sub transaction_id { $_[0]->{attrib}{transaction_id} }
sub command        { $_[0]->{attrib}{command} }

sub frames {
    return [map {
        bless $_->{attrib}, 'DBGp::Client::Response::StackGet::Frame';
    } DBGp::Client::Parser::_nodes($_[0], 'stack')];
}

package DBGp::Client::Response::StackGet::Frame;

use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_accessors(qw(
    level type filename where lineno
));

1;
