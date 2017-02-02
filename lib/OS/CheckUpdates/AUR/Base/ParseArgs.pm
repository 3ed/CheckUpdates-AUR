package OS::CheckUpdates::AUR::Base::ParseArgs;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;

# new(packages|pacman|files => [])
#
# COMMAND  => [ARGS,                         OPTIONAL_OPTS                     ]
# ------------------------------------------------------------------------------
# packages => [qw/name1 ver1/, 'name2', 'ver2', 'name3' => 'ver3'              ]
# pacman   => [['-Qm'],             columns  => { name => 0, ver => 1 }        ]
# pacman   => [['-Sl', 'lan'],      columns  => { name => 1, ver => 2 }        ]
# output   => ['output'             columns  => { name => 1, ver => 2 }        ]
# fh       => [\$FH,                columns  => { name => 0, ver => 1 }        ]
# files    => ['folder',                     regexp => '...[^-]*.pkg.tar.xz$' }]
# files    => [['folder1', 'folder2'],       regexp => '...[^-]*.pkg.tar.xz$' }]


# sub parser($class, @Args) {
#     return bless({}, $class)
#         ->_parser_add(@Args)
#         ->_parser_make
#         ->_parser_sub;
# }

sub parser($class, @Args) {
    return bless({}, $class)
        ->_parser_add(@Args)
        ->_parser_sub;
}

sub _parser_add($self, @Args) {
    confess __PACKAGE__, '->parser(): ',
            'Should be even arguments, we got odd...'
        unless ($#Args > 0 && $#Args % 2);

    $self->{'Args'}->@* = @Args;

    return $self
}

sub _parser_sub($self) {
    return sub ($opt = "hash") {
        confess '(', __PACKAGE__, '->parser(...))->( ->this<- ): ',
                'value must be a string'
            unless ref $opt eq "";

        if(not exists  $self->{'parsed'} or $opt eq "refresh") {
            $opt = "hash" if $opt eq "refresh"; # exception
            $self->{'parsed'}->%* = (); # ???
            $self->_parse_make;
        }

        return $self->_get_make($opt);
    }
}

# reserved: get_*
sub _get_make($self, $opt) {
    confess __PACKAGE__, '->parser(): count value must be a string'
        unless ref $opt eq "";

    if (my $method = $self->can('get_'.$opt)) {
        return $self->$method;
    } else {
        confess __PACKAGE__, '->parser(): unknown counter';
    }
}

# reserved: parse_*
sub _parse_make($self) {
    my $i = 0;
    while ($self->{Args}->@[$i]) {
        confess __PACKAGE__, '->parser(): ',
                'type is ', lc ref $self->{Args}->@[$i],
                ' but should be string: ->here<- => [...]'
            if ref $self->{Args}->@[$i];

        if (
            # ->...<- => [['...', ''...'], ... => ...]
            my $method = $self->can('parse_' . $self->{Args}->@[$i++])
        ) {
            # ... => ->[['...', ''...'], ... => ...]<-
            $self->$method($self->{Args}->@[$i++]->@*);
        } else {
            confess __PACKAGE__, '->parser(): ',
                    'unknown option ->"', $self->{Args}->@[--$i], '"<- => [...]';
                    # ^^ WARNING: if you delete confess ^^ you have minus there
        }
    }

    return $self
}

1;