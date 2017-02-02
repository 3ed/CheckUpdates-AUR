package OS::CheckUpdates::AUR::multiinfo;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use if $ENV{CHECKUPDATES_DEBUG}, 'Smart::Comments';

use Carp;
use LWP::UserAgent;
use JSON;
use URI;

sub new ($class) {
    return bless {
        rpc => { version => 5 }
    }, ref($class) || $class;
}

sub UserAgent ($self) {
    return state $UserAgent = LWP::UserAgent->new(
        'timeout' => 10,
        'agent'   => sprintf(
            'OS::CheckUpdates::AUR/v%s',
            $OS::CheckUpdates::AURVERSION,
        ),
        'protocols_allowed' => ['https'],
    );
}

sub get ($self, @pkgnames) {
    return $self->multiinfo_spliced_by(200, @pkgnames)
}

sub multiinfo_spliced_by($self, $spliced_by, @pkgnames) {
    my @results;

    push @results => $self->multiinfo(
        splice(
            @pkgnames,
            0,
            $spliced_by
        )
    ) while ($#pkgnames >= 0);

    return @results;
}

sub multiinfo ($self, @pkgnames) {
    my $response = $self->UserAgent->get(
        $self->rpc_uri_multiinfo(@pkgnames)
    );

    if ($response->is_success) {
        my $content = decode_json($response->decoded_content);

        confess __PACKAGE__, '->multiinfo(): ',
                'rpc version mismach'
            unless $content->{'version'} eq $self->{'rpc'}->{'version'};

        confess __PACKAGE__, '->multiinfo(): ',
                'aur response with error: ',
                $content->{'error'}
            if $content->{'type'} eq "error";

        return $content->{'results'}->@*
    }

    ### LWP decoded: $response->decoded_content

    $! = 1;
    confess __PACKAGE__, '->multiinfo(): ',
            'LWP status error: ',
            $response->status_line;
}

sub rpc_uri_multiinfo ($self, @pkgnames) {
    state $uri = URI->new(
        'https://aur.archlinux.org/rpc/'
    );

    $uri->query_form(
        'v'     => $self->{'rpc'}->{'version'},
        'type'  => 'info',
        'arg[]' => \@pkgnames
    );

    return $uri
}

1;