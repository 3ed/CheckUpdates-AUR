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

__END__

=head1 NAME

OS::CheckUpdates::AUR::Stats - Stats memory

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 used in upper module as stated stats

=head1 USAGE

 my $cua = OS::CheckUpdates::AUR->new(...);
 print $cua->stats->requested

=head1 SUBROUTINES/METHODS

=head2 requested()

 get (or set!) number of requested packages to aur rpc

=head2 retrived

 get number of retrived packages from aur rpc

=head2 orphaned

 get number of packages that are not found

=head2 updates

 get number of packages that are older than in aur

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