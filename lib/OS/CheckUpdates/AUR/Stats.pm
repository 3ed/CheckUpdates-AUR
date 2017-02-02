package OS::CheckUpdates::AUR::Stats;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

sub _new ($class) {
    return bless {}, ref($class) || $class
}

sub _clear ($self) {
    $self->%* = ();
    return $self;
}

sub requested (
    $self,
    $value = (return $self->{requested} //=  0)
) {
    $self->{requested} = $value;
    return $self
}

sub retrived (
    $self,
    $value = (return $self->{retrived}  //=  0)
) {
    $self->{retrived} = $value;
    return $self
}

sub orphaned (
    $self,
    $value = (return $self->{orphaned}  //= -1)
) {
    $self->{orphaned} = $value;
    return $self
}

sub updates (
    $self,
    $value = (return $self->{updates}   //= -1)
) {
    $self->{updates} = $value;
    return $self
}

1;