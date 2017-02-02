package OS::CheckUpdates::AUR::Base::Filter;
use 5.022;

use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;

sub new($class, $append_on) {
    return bless({'append_on' => $append_on}, $class);
}

sub filter (
    $self,
    $subject,
    $filter_name = ('default'),
    $filter_opts = ({})
) {
    if (my $method = $self->can('filter_'.$filter_name)) {
        $self->$method($subject, $filter_opts->%*);
    } else {
        confess __PACKAGE__, '->(): ',
                'not existed filter has been used "', $filter_name, '"';
    };

    return 1;
}

1;