package OS::CheckUpdates::AUR::Base::Capture;
use 5.022;

use Capture::Tiny qw( capture );
use Carp;

#---------------------------------------------
# Any command output
#---------------------------------------------

sub capture_cmd {
    my ($self, @opts) = @_;

    my ($stdout, $stderr, $exit) = capture {
        local $ENV{LC_ALL} = 'C';
        system(@opts);
    };

    confess $opts[0], "(stderr): ", $stderr
        unless $exit == 0;

    chomp  $stdout;
    return $stdout;
}

sub capture_pacman {
	return shift->capture_cmd('pacman', @_);
}

sub vercmp {
    my ($self, $a, $b) = @_;

    unless (defined $a and defined $b) {
        $! = 1; # exit code
        confess __PACKAGE__, '->vercmp(): '.
                'one or more versions are empty';          # <--
    };

    return 0  if $a eq $b;  # we have here equal

    my $vercmp = $self->capture_cmd('vercmp', $a, $b);

    return $vercmp  if $vercmp =~ /^(-1|0|1)$/osm;

    $! = 1;
    confess __PACKAGE__, '::vercmp(): '.
            'command generate unproper output';            # <--
}

1;