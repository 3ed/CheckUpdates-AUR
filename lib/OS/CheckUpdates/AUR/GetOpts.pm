package OS::CheckUpdates::AUR::GetOpts;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp qw(confess);
use Path::Tiny;

use Getopt::Long qw(
    GetOptionsFromArray
    :config
        gnu_getopt
        no_ignore_case
);

our @ISA;

sub new ($class, %opts) {
    my $self = bless {}, $class;

    foreach (qw(parse argv)) {
        exists $opts{$_} or
            confess __PACKAGE__,
                    ': "', $_, '" is required: ',
                    '->new(->here<- => ...)';
    }

    $self->_auto_load_parents($opts{'parse'}->@*);

    GetOptionsFromArray(
        \$opts{'argv'}->@* => \$self->{'opts'}->%*,
        'help|h',
        $self->_auto_register($opts{'parse'}->@*),
    ) or $self->usage();

    $self->{'opts'}{'help'} and $self->usage();

    my $parsed = $self->_auto_parse($opts{'parse'}->@*);

    return sub {
        my $name = shift         or  return $parsed;
        exists $parsed->{$name}  and return $parsed->{$name};

        # confess if data is uninitialized
        # --------------------------------
        # note: if you do not want this behavior,
        #       do not use it with argument
        confess __PACKAGE__,
                ': data is uninitialized: ',
                '->("',$name,'")';
    }
}

sub _auto_load_parents ($self, @modules) {
    foreach (@modules) {
        my $path = path(__FILE__);
        my $name = sprintf('%s::%s', __PACKAGE__, $_);

        $path = $path
            ->absolute
            ->parent
            ->child($path->basename('.pm'))
            ->child($_ . '.pm');

        $path->is_file or confess
            __PACKAGE__,
            ': can\'t autoload "*::' . $_ . '" module: ',
            '->new(parse => [->here<-, ...], ...)';

        require $path;
        push @ISA, $name;
    }

    return 1;
}

sub _auto_parse ($self, @to_parse) {
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

sub _auto_register ($self, @names) {
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

# default - the helper: overwrite values only this keys
# wich have undefined values
sub defaults ($self, %defaults) {
    while(my ($key, $val) = each %defaults) {
        $self->{'opts'}{$key} //= $val;
    }

    return 1;
}

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