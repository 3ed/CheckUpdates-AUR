=head1 NAME

OS::CheckUpdates::AUR::GetOpts::switch - GetOpts plugin

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 switch options plugin for GetOpts (-s, -a, -F, -f)

=cut

package OS::CheckUpdates::AUR::GetOpts::switch;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

=head1 SUBROUTINES/METHODS

=head2 register_switch()

 registering arguments in getopts

=cut

sub register_switch ($self) {
    return (
        'stdin', '',
        'arg|a=s@',
        'switch|s=s',
        'filter-plugin|F=s',
        'filter-opts|f=s%' => sub { $self->{'opts'}{'filter-opts'}{$_[1]} = $_[2] },
    );
}

=head2 parse_switch()

 parse parameters getted from arguments that been used by user

=cut

sub parse_switch ($self) {
    # Exceptions:
    if($self->{'opts'}{'stdin'} or $self->{'opts'}{''}) {
        # sorry, there can be only one! :)
        $self->{'opts'}{'switch'}
            and warn "Can't be mixed: --stdin and --switch\n"
            and $self->usage();

        $self->{'opts'}{'switch'} = 'stdin';

    } elsif(not $self->{'opts'}{'switch'}) {
        # default mode
        $self->{'opts'}{'switch'} = 'pacman';
    }

    # Let's begin:
    if(my $method = $self->can('switch_'.$self->{'opts'}{'switch'})) {
        return $self->$method();
    } else {
        warn "Option -s get unknown parameter...\n";
        $self->usage();
    }
}

=head2 switch_pacman

 -s pacman

=cut

sub switch_pacman ($self) {
    $self->defaults(
        'filter-opts'   => {},
        'filter-plugin' => 'columns',
        'arg'           => ['-Qm']
    );

    return (
        'pacman' => [
            $self->{'opts'}{'arg'},
            $self->{'opts'}{'filter-plugin'} => {
                $self->{'opts'}{'filter-opts'}->%*
    }]);
}

=head2 switch_files

 -s files

=cut

sub switch_files ($self) {
    $self->defaults(
        'filter-opts' => {}
    );

    if(not $self->{'opts'}{'arg'}) {
        warn "You must use with: -a\n";
        $self->usage();
    }

    return (
        'files' => [
            $self->{'opts'}{'arg'},
            $self->{'opts'}{'filter-opts'}->%*
    ]);
}

=head2 switch_output

 -s output

=cut

sub switch_output ($self) {
    $self->defaults(
        'filter-opts'   => {},
        'filter-plugin' => 'columns'
    );

    return (
        'output' => [
            $self->{'opts'}{'arg'},
            $self->{'opts'}{'filter-plugin'} => {
                $self->{'opts'}{'filter-opts'}->%*
    }]);
}

=head2 switch_stdin

 -s stdin (- and --stdin)

=cut

sub switch_stdin ($self) {
    $self->defaults(
        'filter-opts'   => {},
        'filter-plugin' => 'columns'
    );

    return (
        'fh' => [
            '\*STDIN',
            $self->{'opts'}{'filter-plugin'} => {
                $self->{'opts'}{'filter-opts'}->%*
    }]);
}

sub help_usage_switch($self) {
	return '[-s <switch>] [-a <arg>] [-F <plug>] [-f <opts>]'
}

sub help_options_switch($self) {
	return <<EOF
    -, --stdin
        You can specify packages to check.
        \$ checkupdates-aur   #is equal to:
        \$ pacman -Qm | checkupdates-aur -

    -s, --switch
        pacman (default)
            run pacman and filter output

            -a [arg]
                change/set pacman argument,
                one per -a, eg:
                > pacman -Sl repo
                is equial to:
                > -s pacman -a '-Sl' -a 'repo'
                default: -a '-Qm'

            -F [filter-plugin-name]
                filter plugin name

            -f [opt=val]
                plugin options

            filter-plugins:
                columns (default)
                    filter by column number,
                    options: name, ver
                    default: -f name=0 -f ver=1

        files
            read files names from given folder

            -a [path to folder]

            -f [opt=val]
                filter options

                regexp=[regexp]
                    filter names by matching to regexp,
                    more in: man OS::CheckUpdates::AUR

                recursive=[1/0]
                    would you read from subdirs too?
                    default: 0 (no)

                follow_symlinks
                    would you fellow symlinks?
                    default: 0 (no)

        output
            parse pacman output

            -a [pacman-ouput]
                can be multiply -a

            note: rest opts as in: --switch 'pacman'

        stdin
            same as: --stdin
EOF
}

1;

__END__
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