package OS::CheckUpdates::AUR;

use 5.022;

no warnings 'experimental::smartmatch';

use if $ENV{CHECKUPDATES_DEBUG}, 'Smart::Comments';

use Carp;

use parent q(OS::CheckUpdates::AUR::Base::Capture);

use OS::CheckUpdates::AUR::ParseArgs;
use OS::CheckUpdates::AUR::Stats;
use OS::CheckUpdates::AUR::multiinfo;

our $VERSION = '0.06';



#-------------------------------------------------------------------------------
# Constructor
#-------------------------------------------------------------------------------

use overload
    '""' => sub { print shift->stringify(); "" };

sub new {
    my ($class, @args) = @_;
    return $class->new_lazy(@args)->refresh;
}

sub new_lazy {
    ### OS-CheckUpdates-AUR created here
    my ($class, @args) = @_;
    my $self = bless {}, $class;

    $self->{'requested'} = OS::CheckUpdates::AUR::ParseArgs->parser(@args);

    return $self;
}

#-------------------------------------------------------------------------------
# ROLES DOES
#-------------------------------------------------------------------------------

sub stats {
    return state $stats = OS::CheckUpdates::AUR::Stats->_new();
}

sub requested {
    my ($self, @args) = @_;
    return $self->{'requested'}->(@args)
}

sub multiinfo {
    return state $multiinfo = OS::CheckUpdates::AUR::multiinfo->new();
}

#-------------------------------------------------------------------------------
# Methods
#-------------------------------------------------------------------------------

sub refresh {
    my $self = shift;

    $self->{'updates'} = [];

    $self->stats->_clear; # emptify stats

    $self->stats->requested(
        $self->requested('count')
    );

    if ( $self->stats->requested <= 0 ) {
        ### found 0 packages, nothing to do...
        return $self;
    }

    ### refresh() getting multiinfo()

    my @remotePkgs = $self->multiinfo->get(
        $self->requested('sorted_keys')
    );

    my $localPkgs = $self->requested('hash_copy');

    for (my $i=0; $i <= $#remotePkgs; $i++) {
        my $name = $remotePkgs[$i]->{'Name'};

        exists $localPkgs->{$name}
          or next;

        my $lver = $localPkgs->{$name};
        my $rver = $remotePkgs[$i]->{'Version'};

        delete $localPkgs->{$name};

        $self->vercmp($lver, $rver) eq q/-1/
            and push $self->{'updates'}->@*, [$name, $lver, $rver];
    }

    $self->{'orphans'}->@* = sort keys $localPkgs->%*;

    $self->stats
        ->retrived( $#remotePkgs + 1 )
        ->orphaned( $self->{'orphans'}->$#* + 1 )
        ->updates ( $self->{'updates'}->$#* + 1 );

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

sub stringify {
    my $self = shift;

    return join "\n", map {
        sprintf("%s %s -> %s", $_->@[ 0 .. 2 ])
    } $self->get(@_);
}

sub print {
    my $self = shift;

    printf "%s\n", $self->stringify(@_);
    return 1;
}

sub orphans {
    my $self = shift;

    return wantarray
      ? @{ $self->{'orphans'} }
      : $#{ $self->{'orphans'} } + 1;
}

1;

__END__

=head1 NAME

OS::CheckUpdates::AUR - checkupdates for packages installed from AUR

=head1 VERSION

Version 0.06

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

=head2 new(command => [arguments, optional], ...)

 EXAMPLES:

 COMMAND  => [ARGS,                         OPTIONAL                          ]
 ------------------------------------------------------------------------------
 packages => [qw/name1 ver1/, 'name2', 'ver2', 'name3' => 'ver3'              ]
 pacman   => [['-Qm'],                      columns => { name => 0, ver => 1 }]
 pacman   => [['-Sl', 'lan'],               columns => { name => 1, ver => 2 }]
 output   => ['output'                      columns => { name => 1, ver => 2 }]
 fh       => [\$FH,                         columns => { name => 0, ver => 1 }]
 files    => ['folder',                     regexp  => '...[^-]*.pkg.tar.xz$' ]
 files    => [['folder1', 'folder2'],       regexp  => '...[^-]*.pkg.tar.xz$' ]

=head3 packages

 pairs: name => version

=head3 pacman

 pacman => [Options, Filter]

=head4 Options:

 array of pacman arguments

 eg. pacman -Q -m is equal to pacman => [['-Q', '-m']]

=head4 Filter (optional):

 specific filter that will be used to retrive informations from text

 default is: columns => { name => 0, ver => 1 }

 Available filters:
   columns
     - name - number of column with name
     - ver  - number of column with version

=head3 output

 string with pacman output instead of pacman arguments
 
 everything else the same as in section: new -> pacman

 eg: output => ['output here', Filter]

=head3 fh

 same as output but from fh (eg. \*STDIN)

 for more info look at section: new -> pacman

 eg: fh => [$fh, filter]

=head3 files

 read package list from folder(s) file list(s)

 eg: files => ['folder', Filter]
 eg: files => [['folder', ...], Filter]

=head4 Filter (optional):

 regexp
   Must be named match with name and ver, default:
   '(?<name>.*)-(?<ver>[^-]*-[^-]*)-[^-]*\.pkg\.tar\.xz'

 recursive
   search deeper? (bool)
   default: 0

 follow_symlinks
   follow symlinks? (bool)
   default: 0

=head2 new_lazy(...)

Same as new() but tasks are performed only when needed.

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

Numbers of packages in categories. After arrow: requested, retrived, orphaned, updates

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