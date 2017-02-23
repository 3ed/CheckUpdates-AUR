package OS::CheckUpdates::AUR::Base::ParseArgs;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;

# new(packages|pacman|files => [])
#
# COMMAND  => [ARGS,                         OPTIONAL_OPTS                     ]
# ------------------------------------------------------------------------------
# packages => [qw/name1 ver1/, 'name2', 'ver2', 'name3' => 'ver3'              ]
# pacman   => [['-Qm'],             columns  => { name => 0, ver => 1 }        ]
# pacman   => [['-Sl', 'lan'],      columns  => { name => 1, ver => 2 }        ]
# output   => ['output'             columns  => { name => 1, ver => 2 }        ]
# fh       => [\$FH,                columns  => { name => 0, ver => 1 }        ]
# files    => ['folder',                     regexp => '...[^-]*.pkg.tar.xz$' }]
# files    => [['folder1', 'folder2'],       regexp => '...[^-]*.pkg.tar.xz$' }]


sub parser($class, @Args) {
    return bless({}, $class)
        ->_parser_add(@Args)
        ->_parser_sub;
}

sub _parser_add($self, @Args) {
    confess __PACKAGE__, '->parser(): ',
            'Should be even arguments, we got odd...'
        unless ($#Args > 0 && $#Args % 2);

    $self->{'Args'}->@* = @Args;

    return $self
}

sub _parser_sub($self) {
    return sub ($opt = "hash") {
        confess '(', __PACKAGE__, '->parser(...))->( ->this<- ): ',
                'value must be a string'
            unless ref $opt eq "";

        if(not exists  $self->{'parsed'} or $opt eq "refresh") {
            $opt = "hash" if $opt eq "refresh"; # exception
            $self->{'parsed'}->%* = (); # ???
            $self->_parse_make;
        }

        return $self->_get_make($opt);
    }
}

# reserved: get_*
sub _get_make($self, $opt) {
    confess __PACKAGE__, '->parser(): count value must be a string'
        unless ref $opt eq "";

    if (my $method = $self->can('get_'.$opt)) {
        return $self->$method;
    } else {
        confess __PACKAGE__, '->parser(): unknown counter';
    }
}

# reserved: parse_*
sub _parse_make($self) {
    my $i = 0;
    while ($self->{Args}->@[$i]) {
        confess __PACKAGE__, '->parser(): ',
                'type is ', lc ref $self->{Args}->@[$i],
                ' but should be string: ->here<- => [...]'
            if ref $self->{Args}->@[$i];

        if (
            # ->...<- => [['...', ''...'], ... => ...]
            my $method = $self->can('parse_' . $self->{Args}->@[$i++])
        ) {
            # ... => ->[['...', ''...'], ... => ...]<-
            $self->$method($self->{Args}->@[$i++]->@*);
        } else {
            confess __PACKAGE__, '->parser(): ',
                    'unknown option ->"', $self->{Args}->@[--$i], '"<- => [...]';
                    # ^^ WARNING: if you delete confess ^^ you have minus there
        }
    }

    return $self
}

1;

__END__

=head1 NAME

OS::CheckUpdates::AUR::Base::ParseArgs - base, parse args for ->new()

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

 ""::GetOpts convert for command like arguments to use with
 ""::AUR->new()(--> switch => [...] <--) which use this module
 to parse

 capture output, build-in module

 DO NOT USE IT

=head1 SUBROUTINES/METHODS

=head2 parser()

 and ->('something') to run get_something() from parent module

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