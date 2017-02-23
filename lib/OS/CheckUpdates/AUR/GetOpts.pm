package OS::CheckUpdates::AUR::GetOpts;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp qw(confess);
use Path::Tiny;

use Getopt::Long qw(
    GetOptionsFromArray
    :config
        gnu_getopt
        no_ignore_case
);

our @ISA;

sub new ($class, %opts) {
    my $self = bless {}, $class;

    foreach (qw(parse argv)) {
        exists $opts{$_} or
            confess __PACKAGE__,
                    ': "', $_, '" is required: ',
                    '->new(->here<- => ...)';
    }

    $self->_auto_load_parents($opts{'parse'}->@*);

    GetOptionsFromArray(
        \$opts{'argv'}->@* => \$self->{'opts'}->%*,
        'help|h',
        $self->_auto_register($opts{'parse'}->@*),
    ) or $self->usage();

    $self->{'opts'}{'help'} and $self->usage();

    my $parsed = $self->_auto_parse($opts{'parse'}->@*);

    return sub {
        my $name = shift         or  return $parsed;
        exists $parsed->{$name}  and return $parsed->{$name};

        # confess if data is uninitialized
        # --------------------------------
        # note: if you do not want this behavior,
        #       do not use it with argument
        confess __PACKAGE__,
                ': data is uninitialized: ',
                '->("',$name,'")';
    }
}

sub _auto_load_parents ($self, @modules) {
    my $modl = sprintf('%s::', __PACKAGE__);
    my $path = path(__FILE__)->absolute;
    my $dir  = $path->parent->child($path->basename('.pm'));

    foreach (@modules) {
        $path = $dir->child($_ . '.pm');

        $path->is_file or confess
            __PACKAGE__,
            ': can\'t autoload "*::' . $_ . '" module: ',
            '->new(parse => [->here<-, ...], ...)';

        require $path; push @ISA, $modl . $_;
    }

    return 1;
}

sub _auto_parse ($self, @to_parse) {
    return {
        map {
            if (my $method = $self->can('parse_'.$_)) {
                ( $_ => { $self->$method } )
            } else {
                confess __PACKAGE__,
                        ': method "parse_', $_, '()" do not exist: ',
                        '->new(parse => ["', $_, '", ...]';
            }
        } @to_parse
    };
}

sub _auto_register ($self, @names) {
    return map {
        if (my $method = $self->can('register_'.$_)) {
            $self->$method
        } else {
            confess __PACKAGE__,
                    ': method "register_', $_, '()" do not exist: ',
                    '->new(parse => ["', $_, '", ...]';
        }
    } @names
}

# default - the helper: overwrite values only this keys
# wich have undefined values
sub defaults ($self, %defaults) {
    while(my ($key, $val) = each %defaults) {
        $self->{'opts'}{$key} //= $val;
    }

    return 1;
}

sub usage ($self) {
    say <DATA>;
    exit 1;
}

1;

=head1 NAME

OS::CheckUpdates::AUR::GetOpts - GetOpts plugin

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 misc options plugin for GetOpts (--orphans)

=head1 SUBROUTINES/METHODS

=head2 new()

 create object, options:

    parse => [] - load plugins from s|(GetOpts).pm|$1/this.pm|
    argv => [@ARGV] - argv...

=head2 defaults(arg => value)

 Plugin helpers to set default values if values are undefined

=head2 usage()

 -h, --help

 TODO: if everythin is pluggable, this should be too

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

__DATA__
USAGE:
    checkupdates-aur [-o|--orphans] [-|--stdin]

    checkupdates-aur [-o] [-s <switch>] [-a <arg>]
                     [-F <plug>] [-f <opts>]

    checkupdates-aur [-h|--help]

OPTIONS:
    -o, --orphans
        Show packages that can't be found
        on AUR.

    -, --stdin
        You can specify packages to check.
        $ checkupdates-aur   #is equal to:
        $ pacman -Qm | checkupdates-aur -

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

    -h, --help
        Display this help and exit.

MORE INFO:
    See man page...
