use 5.022;
use strict;
use warnings;

use Module::Build::Pluggable ( AuthorTests =>
                                { test_dirs => 'xt' } );

my $builder = Module::Build::Pluggable->new(
    module_name         => 'OS::CheckUpdates::AUR',
    license             => 'artistic_2',
    dist_author         => q{3ED <krzysztof1987@gmail.com>},
    dist_version_from   => 'lib/OS/CheckUpdates/AUR.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build'                         => 0,
        'Module::Build::Pluggable::AuthorTests' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'JSON'                  => 0,
        'Try::Tiny'             => 0,
        'Capture::Tiny'         => 0,
        'Path::Tiny'            => 0,
        'LWP'                   => 0,
        'LWP::Protocol::https'  => 0,
        'Getopt::Long'          => 0,
    },
    add_to_cleanup       => [ 'OS-CheckUpdates-AUR-*' ],
    add_to_manifest_skip => [ '.git' ],
    create_makefile_pl   => 'traditional',
);


$builder->create_build_script();
