package OS::CheckUpdates::AUR::Base::AutoLoadParents;
use 5.022;
use Carp qw(confess);
use Path::Tiny qw(path);

use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

our @ISA;


sub _auto_load_parents ($self, %opts) {
    exists $opts{'path'}
        and exists $opts{'modprefix'}
        or  confess __PACKAGE__, '->', __SUB__,
            ': path and modprefix are required';

    $opts{'filepostfix'} //= '.pm';

    my $path = path($opts{'path'})->absolute;

    $path->is_file
        and $path =
            $path
                ->parent
                ->child($path->basename('.pm'));

    $path->is_dir or confess __PACKAGE__,
        'can\'t autoload children from folder: ',
        $path, ': ',
        'not found...';


    exists $opts{'register'}
        and $self->{$opts{'register'}} = {
            dir         => $path,
            modprefix   => $opts{'modprefix'},
            filepostfix => $opts{'filepostfix'},
        };



    my $iter = $path->iterator;

    while (my $path = $iter->()) {
        $path->is_file
            or next;

        $path->basename ne (
            my $basename = $path
                ->basename($opts{'filepostfix'})
        )  or next;


        exists $opts{'register'}
            and push(
                $self->{$opts{'register'}}->{'loaded'}->@*,
                $basename
            );


        require $path; push @ISA, $opts{'modprefix'} . $basename;
    }

    return $self;
}

1;