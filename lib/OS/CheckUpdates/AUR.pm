package OS::CheckUpdates::AUR::Stats;
use feature 'signatures';
no warnings 'experimental::signatures';

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
    return $self->{requested} = $value
}

sub retrived (
    $self,
    $value = (return $self->{retrived}  //=  0)
) {
    return $self->{retrived} = $value
}

sub orphaned (
    $self,
    $value = (return $self->{orphaned}  //= -1)
) {
    return $self->{orphaned} = $value
}

sub updates (
    $self,
    $value = (return $self->{updates}   //= -1)
) {
    return $self->{updates} = $value
}

1;

package OS::CheckUpdates::AUR::Capture;

use 5.022;

use Capture::Tiny qw( capture );
use Path::Tiny    qw( path );

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

#---------------------------------------------
# Pacman output
#---------------------------------------------
sub parse_pacman {
    my ($self, $pacman_opts, $filter) = @_;

    return $self->parse_pacman_output(
        $self->capture_cmd('pacman', $pacman_opts->@*),
        $filter
    );
}

sub parse_pacman_output {
    my ($self, $output, $filter) = @_;

    return OS::CheckUpdates::AUR::Filter::Pacman
        ->new($output)
        ->filter($filter)
        ->get();
}

#---------------------------------------------
# Files
#---------------------------------------------

sub capture_files {
    my ($self, $dirs, $regexp) = @_;
    my (@packages, $r);

    $regexp //= '(?<name>.*)-(?<ver>[^-]*-[^-]*)-[^-]*\.pkg\.tar\.xz';

    $r = qr/$regexp/sn
        or confess __PACKAGE__,
            '->capture_files([...], ->here<-): bad regexp';


    dir: for (my $i=0; $i <= $dirs->$#*; $i++) {
        my $dir = path($dirs->@[$i]);

        $dir->is_dir or next dir;

        my $iter = $dir->iterator({
            recurse => 0,
            follow_symlinks => 0,
        });

        file: while (my $file = $iter->()) {
            $file->is_file or next file;

            $file->basename =~ m/$r/
                and defined $+{name}
                and defined $+{ver}
                and push @packages, {$+{name} => $+{ver}};
        }
    }
    return @packages
}

1;

package OS::CheckUpdates::AUR::Filter::Pacman;
use 5.022;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp;

sub new (
    $class,
    $output = (confess(__PACKAGE__, ': new without pacman output'))
) {
    return bless { 'output' => $output }, ref($class) || $class
}

sub output ($self) {
    return $self->{'output'}
}

sub filter ($self, $filter) {
    my %filter_opts;

    %filter_opts = $filter->@[1]->%*
        if defined $filter->@[1];

    if ($filter->@[0] eq 'columns') {
        $self->{'filtered'} = $self->filter_columns(%filter_opts);
    } else { confess 'pacman filter do not recognized' };

    return $self;
}

sub filter_columns ($self, %filter) {
    return {}
        if length $self->output < 5;

    $filter{'name'} //= 0;
    $filter{'ver'}  //= 1;

    return {
        map {
            ( split q{ } )[ $filter{'name'}, $filter{'ver'} ]
        } split /\n/, $self->output
    };
}

sub get ($self) {
    return $self->{'filtered'};
}

1;


package OS::CheckUpdates::AUR;

use 5.022;

no warnings 'experimental::smartmatch';

use if $ENV{CHECKUPDATES_DEBUG}, 'Smart::Comments';

use Carp;
use WWW::AUR::URI qw(rpc_uri);
use WWW::AUR::UserAgent;
use JSON;

use parent -norequire, q(OS::CheckUpdates::AUR::Capture);

our $VERSION = '0.05';

# new(packages|pacman|files, []|{})
# @format = [command, args, optional_opts|undef],
#           [command, args, optional_opts|undef],
#           [...],
# 
# [COMMAND,   ARGS,                          OPTIONAL_OPTS]
# 
# [packages,  [[name, ver], [name2, ver2]],  undef]
# [pacman,    ['-Qqm'],                      { columns => { name => 1, ver => 2 } }]
# [files,     ['folder1', 'folder2'],        { regexp => '...[^-]*.pkg.tar.xz$' }]
# [output,    ['output']                     { columns => { name => 1, ver => 2 } }]
#
# or?
#
# packages => [['-Qm'], { columns => { name => 1, ver => 2 } }] # de-facto paired array


sub new {
    ### OS-CheckUpdates-AUR created here
    return (bless {}, shift)->_new_parseArgs(@_)->refresh;
}

sub new_lazy {
    ### OS-CheckUpdates-AUR lazy created here
    return (bless {}, shift)->_new_parseArgs(@_); # TODO: Do not parse here
}

    sub _new_parseArgs {
        my ($self, %args) = @_;

        foreach (keys %args) {
            when ("packages") {
                $self->{'localQueryPkgs'} = $self->_new_parseArgs_packages( $args{$_} )}
            default {
                confess "Unknown option"}
        }

        return $self
    }

    sub _new_parseArgs_packages {
        my ($self, $packages) = @_;

        given (ref $packages) {
            when("HASH") {
                return $packages; }
            when ("") {
                ($packages eq ":forgein" or $packages eq "")
                    and return $self->_get_forgeinPkgs(); }
        }

        confess "Unknown option";
    }

    sub _get_forgeinPkgs {
        return {
            map {
                ( split q{ } )[ 0, 1 ]
            } split /\n/, shift->capture_cmd(qw(pacman -Qm))
        };
    }

sub stats {
    my $self = shift;
    return $self->{'stats'} //= OS::CheckUpdates::AUR::Stats->_new();
}

sub refresh {
    my $self = shift;

    $self->{'updates'} = [];

    $self->stats->_clear; # emptify

    $self->stats
    ->requested(
        $#{[keys $self->{localQueryPkgs}->%*]} + 1
    );

    if ( $self->stats->requested <= 0 ) {
        ### found 0 packages, nothing to do...
        return $self;
    }

    ### refresh() getting multiinfo()

    my @remotePkgs = $self
        ->multiinfo( sort keys $self->{localQueryPkgs}->%* )
        ->{'results'}
        ->@*;

    my $localPkgs = {$self->{localQueryPkgs}->%*};

    for (my $i=0; $i <= $#remotePkgs; $i++) {
        my $name = $remotePkgs[$i]->{'Name'};

        exists $localPkgs->{$name}
          or next;

        my $lver = $localPkgs->{$name};
        my $rver = $remotePkgs[$i]->{'Version'};

        delete $localPkgs->{$name};

        $self->vercmp([$lver, $rver]) eq q/-1/
            and push $self->{'updates'}->@*, [$name, $lver, $rver];
    }

    $self->{'orphans'}->@* = sort keys $localPkgs->%*;

    $self->stats->retrived($#remotePkgs + 1);
    $self->stats->orphaned($self->{'orphans'}->$#* + 1);
    $self->stats->updates ($self->{'updates'}->$#* + 1);

    ### Requested: $self->stats->requested
    ###  Retrived: $self->stats->retrived
    ###  Orphaned: $self->stats->orphaned
    ###   Updates: $self->stats->updates

    return $self;
}

sub get {
    my $self = shift;

    ### get() return updates
    $#_ == -1
      and return $self->{'updates'}->@*
      or return grep { $_[0] ~~ @_ } $self->{'updates'}; # TODO: $_ & @_ ???
}


sub print {
    my $self = shift;

    foreach ( $self->get(@_) ) {
        printf "%s %s -> %s\n", @{$_}[ 0 .. 2 ];
    }

    return 1;
}

sub orphans {
    my $self = shift;

    return wantarray
      ? @{ $self->{'orphans'} }
      : $#{ $self->{'orphans'} } + 1;
}

sub vercmp {
    my ( $self, $opts ) = @_;

    unless (
        $opts->$#* == 1
            and defined $opts->@[0]
            and defined $opts->@[1]
    ) {
        $! = 1; # exit code
        confess __PACKAGE__,
            '::vercmp(): one or more versions are empty';
    };

    return 0  if $opts->@[0] eq $opts->@[1];

    my $vercmp = $self->capture_cmd('vercmp', $opts->@*);

    return $vercmp  if $vercmp =~ /^(-1|0|1)$/osm;

    $! = 1;
    confess  __PACKAGE__, '::vercmp(): command generate unproper output';
}

sub multiinfo {
    my $self = shift;
    my $lwp  = WWW::AUR::UserAgent->new(
        'timeout' => 10,
        'agent'   => sprintf(
            'WWW::AUR/v%s (OS::CheckUpdates::AUR/v%s)',
            $WWW::AUR::VERSION, $VERSION,
        ),
        'protocols_allowed' => ['https'],
    );

    my $response = $lwp->get( rpc_uri( 'multiinfo', @_ ) );

    $response->is_success
      and return decode_json( $response->decoded_content );

    ### LWP decoded: $response->decoded_content

    $! = 1;
    confess __PACKAGE__, '::multiinfo(): LWP status error: '
          . $response->status_line;
}

1;

__END__

=head1 NAME

OS::CheckUpdates::AUR - checkupdates for packages installed from AUR

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

checkupdates for aur

Example of code:

    use OS::CheckUpdates::AUR;

    my $foo = OS::CheckUpdates::AUR->new();

    # Print available updates:

    $foo->print();
    # or
    printf("%s %s -> %s\n", @{$_}[0..2]) foreach (@{$foo->get()});

=head1 SUBROUTINES/METHODS

=head2 new()

New...

=head2 get(@)

Get array with checkupdates: [name, local_ver, aur_ver]

Options:
- empty: return all packages
- (name, ...): return only this packages

Note: scalar return count (warning: works only with empty options)

=head2 print(@)

Print checkupdates into stdout in chekupdates format.

Options:
- empty: print all packages
- (name, ...): print only this packages

=head2 orphans()

Show packages that can't be found on AUR.

Note: scalar return orphans count

=head2 stats()

Show packages that can't be found on AUR.

Note: scalar return orphans count

=head2 refresh(%)

Create/retrive/parse/refresh data about packages.

Options:
- empty: check list of installed packages which are not found in sync db
- pairs (package_name => package_ver, ...): check only this packages

=head2 vercmp($$)

Compare two versions in pacman way. Frontend for vercmp command.

=head2 multiinfo(@)

Fast method to get info about multiple packages.

=head1 AUTHOR

3ED, C<< <krzysztof1987 at gmail.com> >>



=head1 BUGS

Please report any bugs or feature requests to C<bug-checkupdates-aur at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OS-CheckUpdates-AUR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OS::CheckUpdates::AUR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OS-CheckUpdates-AUR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OS-CheckUpdates-AUR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OS-CheckUpdates-AUR>

=item * Search CPAN

L<http://search.cpan.org/dist/OS-CheckUpdates-AUR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 3ED.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut