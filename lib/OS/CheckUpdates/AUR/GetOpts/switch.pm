package OS::CheckUpdates::AUR::GetOpts::switch;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

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

1;