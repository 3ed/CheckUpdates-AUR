package OS::CheckUpdates::AUR::GetOpts;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp qw(confess);
use Getopt::Long qw(
    GetOptionsFromArray
    :config
        gnu_getopt
        no_ignore_case
);


sub new ($class, %opts) {
    my $self = bless {}, $class;

    foreach (qw(parse argv)) {
        exists $opts{$_} or
            confess __PACKAGE__,
                    ': "', $_, '" is required: ',
                    '->new(->here<- => ...)';
    }

    GetOptionsFromArray(\$opts{'argv'}->@* => \$self->{'opts'}->%*,
        'help|h',
        $self->register($opts{'parse'}->@*),
    ) or $self->usage();

    $self->{'opts'}{'help'} and $self->usage();

    my $parsed = $self->parse($opts{'parse'}->@*);

    return sub {
        my $name = shift or return $parsed;
        exists $parsed->{$name} and return $parsed->{$name};

        # confess if data is uninitialized
        # --------------------------------
        # note: if you do not want this behavior,
        #       do not use it with argument
        confess __PACKAGE__,
                ': data is uninitialized: ',
                '->("',$name,'")';
    }
}

# default - the helper: overwrite values only this keys
# wich have undefined values
sub defaults ($self, %defaults) {
    while(my ($key, $val) = each %defaults) {
        $self->{'opts'}{$key} //= $val;
    }

    return 1;
}

sub parse ($self, @to_parse) {
    return {
        map {
            if (my $method = $self->can('parse_'.$_)) {
                ( $_ => { $self->$method } )
            } else {
                confess __PACKAGE__,
                        ': method "parse_', $_, '()" do not exist: ',
                        '->new(parse => ["', $_, '", ...]';
            }
        } @to_parse
    };
}

sub register ($self, @names) {
    $self->{'opts'}{'help'} and $self->usage();

    return map {
        if (my $method = $self->can('register_'.$_)) {
            $self->$method
        } else {
            confess __PACKAGE__,
                    ': method "register_', $_, '()" do not exist: ',
                    '->new(parse => ["', $_, '", ...]';
        }
    } @names
}

#--------------------------------------------------
# Above is a base/common functionality
#--------------------------------------------------
#
# arguments related to --switch:

sub register_switch ($self) {
    return (
        'stdin', '',
        'arg|a=s@',
        'switch|s=s',
        'filter-plugin|F=s',
        'filter-opts|f=s%' => sub { $self->{'opts'}{'filter-opts'}{$_[1]} = $_[2] },
    );
}

sub parse_switch ($self) {
    # Exceptions:
    if($self->{'opts'}{'stdin'} or $self->{'opts'}{''}) {
        # sorry, there can be only one! :)
        $self->{'opts'}{'switch'}
            and warn "Can't be mixed: --stdin and --switch\n"
            and $self->usage();

        $self->{'opts'}{'switch'} = 'stdin';

    } elsif(not $self->{'opts'}{'switch'}) {
        # default mode
        $self->{'opts'}{'switch'} = 'pacman';
    }

    # Let's begin:
    if(my $method = $self->can('switch_'.$self->{'opts'}{'switch'})) {
        return $self->$method();
    } else {
        warn "Option -s get unknown parameter...\n";
        $self->usage();
    }
}


sub switch_pacman ($self) {
    $self->defaults(
        'filter-opts'   => {},
        'filter-plugin' => 'columns',
        'arg'           => ['-Qm']
    );

    return (
        'pacman' => [
            $self->{'opts'}{'arg'},
            $self->{'opts'}{'filter-plugin'} => {
                $self->{'opts'}{'filter-opts'}->%*
    }]);
}


sub switch_files ($self) {
    $self->defaults(
        'filter-opts' => {}
    );

    if(not $self->{'opts'}{'arg'}) {
        warn "You must use with: -a\n";
        $self->usage();
    }

    return (
        'files' => [
            $self->{'opts'}{'arg'},
            $self->{'opts'}{'filter-opts'}->%*
    ]);
}

sub switch_output ($self) {
    $self->defaults(
        'filter-opts'   => {},
        'filter-plugin' => 'columns'
    );

    return (
        'output' => [
            $self->{'opts'}{'arg'},
            $self->{'opts'}{'filter-plugin'} => {
                $self->{'opts'}{'filter-opts'}->%*
    }]);
}

sub switch_stdin ($self) {
    $self->defaults(
        'filter-opts'   => {},
        'filter-plugin' => 'columns'
    );

    return (
        'fh' => [
            '\*STDIN',
            $self->{'opts'}{'filter-plugin'} => {
                $self->{'opts'}{'filter-opts'}->%*
    }]);
}

#
# other root arguments:

sub register_misc ($self) {
    return (
        'orphans|o'
    );
}

sub parse_misc ($self) {
    return $self->{'opts'}->%{qw(
        orphans
    )}
}

#
# usage (help screen):

sub usage ($self) {
    say <DATA>;
    exit 1;
}

1;

__DATA__
USAGE:
    checkupdates-aur [-o|--orphans] [-|--stdin]

    checkupdates-aur [-o] [-s <switch>] [-a <arg>]
                     [-F <plug>] [-f <opts>]

    checkupdates-aur [-h|--help]

OPTIONS:
    -o, --orphans
        Show packages that can't be found
        on AUR.

    -, --stdin
        You can specify packages to check.
        $ checkupdates-aur   #is equal to:
        $ pacman -Qm | checkupdates-aur -

    -s, --switch
        pacman (default)
            run pacman and filter output

            -a [arg]
                change/set pacman argument,
                one per -a, eg:
                > pacman -Sl repo
                is equial to:
                > -s pacman -a '-Sl' -a 'repo'
                default: -a '-Qm'

            -F [filter-plugin-name]
                filter plugin name

            -f [opt=val]
                plugin options

            filter-plugins:
                columns (default)
                    filter by column number,
                    options: name, ver
                    default: -f name=0 -f ver=1

        files
            read files names from given folder

            -a [path to folder]

            -f [opt=val]
                filter options

                regexp=[regexp]
                    filter names by matching to regexp,
                    more in: man OS::CheckUpdates::AUR

                recursive=[1/0]
                    would you read from subdirs too?
                    default: 0 (no)

                follow_symlinks
                    would you fellow symlinks?
                    default: 0 (no)

        output
            parse pacman output

            -a [pacman-ouput]
                can be multiply -a

            note: rest opts as in: --switch 'pacman'

        stdin
            same as: --stdin

    -h, --help
        Display this help and exit.

MORE INFO:
    See man page...