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
    'Test::DBGp'                => '0.06',
    'DBGp::Client'              => 0,
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

find({ wanted => \&_fill_dbgp, no_chdir => 1 }, 'DB');
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
            'blib/man3/Devel::Debug::DBGp.3',
    },
    ( $mm_ver >= 6.48 ?     ( MIN_PERL_VERSION  => 5.008 ) :
                            () ),
    ( $mm_ver >= 6.64 ?     ( TEST_REQUIRES     => \%test_requires ) :
      $mm_ver >= 6.5503 ?   ( BUILD_REQUIRES    => \%test_requires ) :
                            ( PREREQ_PM         => \%test_requires ) ),
    ( $mm_ver >= 6.31 ?     ( LICENSE           => 'artistic' ) :
                            () ),
    ( $mm_ver >= 6.46 ?
      ( META_MERGE  => {
          "meta-spec" => { version => 2 },
          no_index    => {
              file      => [ 'perl5db.pl' ],
              directory => [ 'DB' ],
          },
          resources   => {
              license     => [ 'http://dev.perl.org/licenses/artistic.html' ],
#              homepage    => 'https://github.com/mbarbon/perl-remote-debugging-client',
              bugtracker  => {
                  web    => 'https://github.com/mbarbon/perl-remote-debugging-client/issues',
              },
              repository  => {
                  url  => 'git@github.com:mbarbon/perl-remote-debugging-client.git',
                  web  => 'https://github.com/mbarbon/perl-remote-debugging-client',
                  type => 'git',
              },
          },
        },
      ) : () ),
);
