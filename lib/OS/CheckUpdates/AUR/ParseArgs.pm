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

sub filter_pacman($self, @opts) {  # TODO: plugin system
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


__END__

=head1 NAME

OS::CheckUpdates::AUR::ParseArgs - parse perl array passed to upper module

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 used in upper module to parse perl array arguments passed to new

 OS::CheckUpdates::AUR->new( -->here<-- );

=head1 SUBROUTINES/METHODS

=head2 filter_pacman

 state to OS::CheckUpdates::AUR::Filter::Pacman

=head2 parse_files
=head2 parse_fh
=head2 parse_pacman
=head2 parse_output
=head2 parse_packages

 parse_THIS

 OS::CheckUpdates::AUR->new( -->THIS<-- => [...] );

=head2 get_count
=head2 get_keys
=head2 get_sorted_keys
=head2 get_hash_copy
=head2 get_hash

 get_THIS

 my $cua = OS::CheckUpdates::AUR->new(...);

 $cua->retrived(THIS);

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