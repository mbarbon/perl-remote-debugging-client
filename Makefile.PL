#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Find;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %test_requires = (
    'Test::Differences'         => 0,
    'XML::Parser'               => 0,
    'XML::Parser::EasyTree'     => 0,
);

my %pm = (
    'perl5db.pl'    => 'blib/lib/dbgp-helper/perl5db.pl',
);

sub _fill_dbgp {
    return unless -f $_ && /\.pm$/;
    $pm{$_} = "blib/lib/dbgp-helper/$_";
}

sub _fill_lib {
    return unless -f $_ && /\.pm$/;
    $pm{$_} = "blib/lib/$_";
}

find({ wanted => \&_fill_dbgp, no_chdir => 1 }, 'DB', 'Syntax');
find({ wanted => \&_fill_lib,  no_chdir => 1 }, 'Devel');

WriteMakefile(
    NAME              => "Devel::Debug::DBGp",
    PM                => \%pm,
    VERSION_FROM      => "Devel/Debug/DBGp.pm",
    ABSTRACT_FROM     => "Devel/Debug/DBGp.pm",
    AUTHOR            => 'Mattia Barbon <mbarbon@cpan.org>',
    MAN3PODS          => {
        # do not generate manpages for all internal POD
        'Devel/Debug/DBGp.pm'   =>
            'blib/man3/Devel::Debug::Devel::Debug::DBGp.3',
    },
    ( $mm_ver >= 6.48 ?     ( MIN_PERL_VERSION  => 5.006 ) :
                            () ),
    ( $mm_ver >= 6.64 ?     ( TEST_REQUIRES     => \%test_requires ) :
      $mm_ver >= 6.5503 ?   ( BUILD_REQUIRES    => \%test_requires ) :
                            ( PREREQ_PM         => \%test_requires ) ),
    ( $mm_ver >= 6.31 ?     ( LICENSE           => 'artistic' ) :
                            () ),
);