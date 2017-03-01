=head1 NAME

OS::CheckUpdates::AUR::ParseArgs::parserPacmanOutput - parse -> pacman, output, fh

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 autoloaded by ParseArgs

=head1 USAGE

 my $sub = parent->parse('pacman' => [...])
 my $sub = parent->parse('output' => [...])
 my $sub = parent->parse('fh'     => [...])

=cut

package OS::CheckUpdates::AUR::ParseArgs::parserPacmanOutput;
use 5.022;
use feature  qw(signatures postderef);
no  warnings qw(experimental::signatures experimental::postderef);
use Carp     qw(confess);
use parent   qw(OS::CheckUpdates::AUR::Base::Capture);

=head1 SUBROUTINES/METHODS

=head2 filter_pacman

 pacman output filters

=cut

use OS::CheckUpdates::AUR::Filter::Pacman;

sub filter_pacman($self, @opts) {  # TODO: plugin system
    state $FilterOutput = OS::CheckUpdates::AUR::Filter::Pacman->new(
        \$self->{'parsed'}->%*
    );

    return $FilterOutput->filter(@opts);
}


=head2 parse_fh

 fh => [ \$fh, filter-plugin-name => { filter-opts => values } ]

=cut

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

=head2 parse_pacman

 pacman => [ ['pacman args', ...], filter-plugin-name => { filter-opts => values } ]

=cut

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

=head2 parse_output

 output => [ 'pacman output', filter-plugin-name => { filter-opts => values } ]

=cut

sub parse_output(
    $self,
    $output,
    $filter_name = "columns",
    $filter_opts = {}
) {
    $self->filter_pacman($output, $filter_name, $filter_opts);

    return $self;
}


1;

__END__
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
