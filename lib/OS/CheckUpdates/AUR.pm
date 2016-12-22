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

package OS::CheckUpdates::AUR::Capture;
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

1;

package OS::CheckUpdates::AUR::Filter::Pacman;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;

sub new (
    $class,
    $output = (confess(__PACKAGE__, ': new without pacman output'))
) {
    return bless { 'output' => $output }, ref($class) || $class
}

sub append_on ($self, $ref) {
    $self->{'filtered'} = $ref;
    return $self;
}

sub filter ($self, $name, $opts) {
    if (my $method = $self->can('filter_'.$name)) {
        $self->$method($opts->%*);
    } else {
        confess __PACKAGE__, '->filter(): ',
                'pacman filter "', $name, '" do not recognized'
    };

    return $self;
}

sub filter_columns ($self, %filter) {
    return {}
        if length $self->get_output < 5;

    $filter{'name'} //= 0;
    $filter{'ver'}  //= 1;

    $self->{'filtered'}->{$_->[0]} = $_->[1]
        for map {[
            ( split q{ } )[ $filter{'name'}, $filter{'ver'} ]
        ]} split /\n/, $self->get_output;

    return $self;
}

sub get_output ($self) {
    return $self->{'output'}
}

sub get ($self) {
    return $self->{'filtered'};
}

1;

package OS::CheckUpdates::AUR::Base::ParseArgs;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;

# new(packages|pacman|files => [])
#
# COMMAND  => [ARGS,                         OPTIONAL_OPTS                     ]
# ------------------------------------------------------------------------------
# packages => [[[name, ver], [name2, ver2]]                                    ]
# pacman   => [['-Qm'],             columns  => { name => 0, ver => 1 }        ]
# pacman   => [['-Sl', 'lan'],      columns  => { name => 1, ver => 2 }        ]
# files    => ['folder',                     regexp => '...[^-]*.pkg.tar.xz$' }]
# files    => [['folder1', 'folder2'],       regexp => '...[^-]*.pkg.tar.xz$' }]
# output   => ['output'                      columns => { name => 1, ver => 2 }]


# sub parser($class, @Args) {
#     return bless({}, $class)
#         ->_parser_add(@Args)
#         ->_parser_make
#         ->_parser_sub;
# }

sub parser($class, @Args) {
    return bless({}, $class)
        ->_parser_add(@Args)
        ->_parser_sub;
}

sub _parser_add($self, @Args) {
    confess __PACKAGE__, '->parser(): ',
            'Should be even arguments, we got odd...'
        unless $#Args % 2;

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

package OS::CheckUpdates::AUR::ParseArgs;
use 5.022;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;
use Path::Tiny qw( path );
use parent -norequire, qw(
    OS::CheckUpdates::AUR::Base::ParseArgs
    OS::CheckUpdates::AUR::Capture
);

#-------------------------------------------------------------------------------
# parse_* // parse_something == ->parser('something' => [@args])
#-------------------------------------------------------------------------------

sub parse_files($self, $dirs, %opts) {
    $dirs = [$dirs] unless ref $dirs; # string to array

    confess __PACKAGE__, '->parser(): ',
            'type is ', lc ref $dirs,
            ' but should be string or array: ... => [->here<-, ...]'
        if ref $dirs ne 'ARRAY';


    $opts{'regexp'}          //= '(?<name>.*)-(?<ver>[^-]*-[^-]*)-[^-]*\.pkg\.tar\.xz';
    $opts{'recursive'}       //= 0;
    $opts{'follow_symlinks'} //= 0;


    my $r = qr/$opts{'regexp'}/sn
        or confess __PACKAGE__, '->parser(): ',
                   'bad regexp: files => ['...', regexp => ->here<-]';


    dir: for (my $i=0; $i <= $dirs->$#*; $i++) {
        my $dir = path($dirs->@[$i]);

        $dir->is_dir or next dir;

        ### iterator method
        #
        # my $iter = $dir->iterator({
        #     recurse         => $opts{'recursive'},
        #     follow_symlinks => $opts{'follow_symlinks'},
        # });

        # file: while (my $file = $iter->()) {
        #     $file->is_file
        #         and $file->basename =~ m/$r/
        #         and defined $+{name}
        #         and defined $+{ver}
        #         and $self->{'parsed'}->{$+{name}} = $+{ver};
        # }

        ### visit method
        #
        $dir->visit(sub{
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

sub parse_pacman(
    $self,
    $pacman_opts,
    @filter
) {
    return $self->parse_output(
        $self->capture_cmd('pacman', $pacman_opts->@*),
        @filter
    );
}

sub parse_output(
    $self,
    $output,
    $filter_name = "columns",
    $filter_opts = {}
) {
    OS::CheckUpdates::AUR::Filter::Pacman
        ->new($output)
        ->append_on( \$self->{'parsed'}->%* )
        ->filter($filter_name, $filter_opts);

    return $self;
}

sub parse_packages($self, $opts1, %opts2) {

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


#-------------------------------------------------------------------------------
# Constructor
#-------------------------------------------------------------------------------


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

    my @remotePkgs = $self
        ->multiinfo( $self->requested('sorted_keys') )
        ->{'results'}
        ->@*;

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
    my ( $self, $a, $b ) = @_;

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

=head2 new_lazy()

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