package OS::CheckUpdates::AUR::ParseArgs;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;
use Path::Tiny qw( path );
use OS::CheckUpdates::AUR::Filter::Pacman;

use parent qw(
    OS::CheckUpdates::AUR::Base::ParseArgs
    OS::CheckUpdates::AUR::Base::Capture
);

sub filter_pacman($self, @opts) {
    state $FilterOutput = OS::CheckUpdates::AUR::Filter::Pacman->new(
        \$self->{'parsed'}->%*
    );

    return $FilterOutput->filter(@opts);
}

#-------------------------------------------------------------------------------
# parse_* // parse_something == ->parser('something' => [@args])
#-------------------------------------------------------------------------------

sub parse_files($self, $dirs, %opts) {
    $dirs = [$dirs] if ref $dirs ne 'ARRAY'; # any to array


    $opts{'regexp'}          //= '(?<name>.*)-(?<ver>[^-]*-[^-]*)-[^-]*\.pkg\.tar\.xz';
    $opts{'recursive'}       //= 0;
    $opts{'follow_symlinks'} //= 0;


    my $r = qr/$opts{'regexp'}/sn
        or confess __PACKAGE__, '->parser(): ',
                   'bad regexp: ',
                   'files => [[...], regexp => ->here<-]';


    dir: for (my $i=0; $i <= $dirs->$#*; $i++) {

        # confess if not string
        confess __PACKAGE__, '->parser(): ',
                'type is ', lc ref $dirs->@[$i], ' ',
                'but should be string: ',
                'files => [->here<-, ...]'
            if ref $dirs->@[$i] ne '';

        # initiate Path::Tiny
        my $dir = path($dirs->@[$i]);

        # confess if is not dir
        confess __PACKAGE__, '->parser(): ',
                'path is not a folder: ',
                'files => [->here<-, ...]'
            unless $dir->is_dir;

        # scour through dir(s)
        $dir->visit(sub{
            # if is file and not link and regexp pass
            $_->is_file
                and $_->basename =~ m/$r/
                and defined $+{name}
                and defined $+{ver}
                and $self->{'parsed'}->{$+{name}} = $+{ver};
        },
        {
            recurse         => $opts{'recursive'},
            follow_symlinks => $opts{'follow_symlinks'},
        });
    }


    return $self;
}

sub parse_fh(
    $self,
    $fh,
    @filter
) {
    confess __PACKAGE__, '->parser(): ',
            'type is ', lc ref $fh, ' ',
            'but should be fh: ',
            'fh => [->here<-, ...]'
        unless ref $fh eq 'GLOB';

    # read fh then pass to parse_output
    $self->parse_output(
        join("", <$fh>),
        @filter
    );

    return $self;
}

sub parse_pacman(
    $self,
    $pacman_opts,
    @filter
) {
    $self->parse_output(
        $self->capture_cmd('pacman', $pacman_opts->@*),
        @filter
    );

    return $self;
}

sub parse_output(
    $self,
    $output,
    $filter_name = "columns",
    $filter_opts = {}
) {
    $self->filter_pacman($output, $filter_name, $filter_opts);

    return $self;
}

sub parse_packages(
    $self,
    %packages
) {
    $self->{'parsed'}->@{keys %packages} = values %packages;
    return $self;
}

#-------------------------------------------------------------------------------
# get_* // get_something == ->('something')
#-------------------------------------------------------------------------------

sub get_count($self) {
    return scalar keys $self->{'parsed'}->%*;
}

sub get_keys($self) {
    return keys $self->{'parsed'}->%*
}

sub get_sorted_keys($self) {
    return sort keys $self->{'parsed'}->%*
}

sub get_hash_copy($self) {
    return {$self->{'parsed'}->%*}
}

sub get_hash($self) {
    return \$self->{'parsed'}->%*
}

1;