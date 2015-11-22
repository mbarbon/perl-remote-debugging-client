package DBGp::Client::Response::Step;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

__PACKAGE__->make_accessors(qw(
    transaction_id reason command status
));

1;
