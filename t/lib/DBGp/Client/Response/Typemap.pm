package DBGp::Client::Response::Typemap;

use strict;
use warnings;

use DBGp::Client::Response::Property;

sub transaction_id { $_[0]->{attrib}{transaction_id} }
sub command        { $_[0]->{attrib}{command} }

sub types {
    return [
        map bless($_->{attrib}, 'DBGp::Client::Response::Typemap::Type'),
            DBGp::Client::Parser::_nodes($_[0], 'map')
    ];
}

package DBGp::Client::Response::Typemap::Type;

use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_accessors(qw(
    type name
));

sub xsi_type { $_[0]->{'xsi:type'} }

1;
