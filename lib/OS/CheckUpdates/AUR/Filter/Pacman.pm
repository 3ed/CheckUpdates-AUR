package OS::CheckUpdates::AUR::Filter::Pacman;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;

use parent q(OS::CheckUpdates::AUR::Base::Filter);

sub filter_default ($self, @pass) {
    return $self->filter_columns(@pass)
};

sub filter_columns ($self, $subject, %column) {
    return
        if length $subject < 5;

    $column{'name'} //= 0;
    $column{'ver'}  //= 1;

    $self->{'append_on'}->{$_->[0]} = $_->[1]
        for map {[
            ( split q{ } )[ $column{'name'}, $column{'ver'} ]
        ]} split /\n/, $subject;

    return 1;
}

1;