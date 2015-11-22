package DBGp::Client::Response::Property;

use strict;
use warnings;

use MIME::Base64 qw(decode_base64);

sub name { $_[0]->{attrib}{name} }
sub fullname { $_[0]->{attrib}{fullname} }
sub constant { $_[0]->{attrib}{constant} }
sub type { $_[0]->{attrib}{type} }
sub children { $_[0]->{attrib}{children} }
sub numchildren { $_[0]->{attrib}{children} ? $_[0]->{attrib}{numchildren} : 0 }

sub value {
    my $value = DBGp::Client::Parser::_node($_[0], 'value');

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
