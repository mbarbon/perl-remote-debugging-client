package Module::Build::DBGp;

use strict;
use warnings;
use parent qw(Module::Build);

sub new {
    my $self = shift->SUPER::new(@_);

    $self->add_build_element('debugger');

    return $self;
}

sub find_debugger_files {
    my ($self) = @_;
    my $pm_files = [
        @{$self->rscan_dir('DB', qr/\.pm$/)},
        @{$self->rscan_dir('Syntax', qr/\.pm$/)},
    ];

    return {
        ('perl5db.pl' => File::Spec->catfile('lib', 'dbgp-helper', 'perl5db.pl')),
        (map +($_ => File::Spec->catfile('lib', 'dbgp-helper', $_)),
         map $self->localize_file_path($_),
             @$pm_files),
    };
}

sub htmlify_pods { }
sub manify_lib_pods { }

1;
