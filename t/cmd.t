#!/usr/bin/perl -T
use v5.16;
use strict;
use warnings;
use Test::More tests => 2;

use IPC::Cmd qw(can_run);

ok(can_run("pacman"), 'pacman is installed');
ok(can_run("vercmp"), 'vercmp is installed');