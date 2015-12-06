package Devel::Debug::DBGp;

=head1 NAME

Devel::Debug::DBGp - Perl DBGp debugger (derived from Komodo remote debugging helper)

=cut

use strict;
use warnings;

our $VERSION = '0.03';

sub debugger_path {
    for my $dir (@INC) {
        return "$dir/dbgp-helper"
            if -f "$dir/dbgp-helper/perl5db.pl"
    }

    die "Unable to find debugger library 'dbgp-helper' in \@INC (@INC)";
}

1;

__END__

=head1 AUTHORS

Mattia Barbon <mbarbon@cpan.org> - packaging and misc changes/fixes

derived from ActiveState Komodo Remote Debugging Helper

derived from the Perl 5 debugger (perl5db.pl)

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the
L<Artistic License|http://www.opensource.org/licenses/artistic-license.php>.

=cut
