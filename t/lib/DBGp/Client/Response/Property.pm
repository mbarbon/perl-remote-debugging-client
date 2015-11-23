package DBGp::Client::Response::Property;

use strict;
use warnings;
use parent qw(DBGp::Client::Response::Simple);

use MIME::Base64 qw(decode_base64);

__PACKAGE__->make_attrib_accessors(qw(
    name fullname constant type children
));

sub numchildren { $_[0]->{attrib}{children} ? $_[0]->{attrib}{numchildren} : 0 }

sub value {
    my $value = DBGp::Client::Parser::_node($_[0], 'value');

    if (!$value) {
        # Xdebug compat
        my $text = DBGp::Client::Parser::_text($_[0]);

        return undef unless $text =~ /\S/;

        my $encoding = $_[0]->{attrib}{encoding};
        die "Only supports base64" unless $encoding eq 'base64';

        return decode_base64($text) ;
    }

    if (my $encoding = $value->{attrib}{encoding}) {
        die "Only supports base64" unless $encoding eq 'base64';

        my $text = DBGp::Client::Parser::_text($value);

        return length($text) ? decode_base64($text) : undef;
    }
}

sub childs {
    return [] unless $_[0]->children;

    return [
        map bless($_, 'DBGp::Client::Response::Property'),
            DBGp::Client::Parser::_nodes($_[0], 'property'),
    ];
}

1;
