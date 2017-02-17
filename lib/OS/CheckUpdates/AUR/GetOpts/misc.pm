package OS::CheckUpdates::AUR::GetOpts::misc;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

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

1;