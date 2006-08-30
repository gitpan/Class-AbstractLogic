#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;
use lib 't/lib';

use_ok('Class::AbstractLogic');
use aliased 'Class::AbstractLogic::Manager';

my $calm = Manager->new(
    config => {
        TestLogic => {
            foo => 23,
        },
    },
);

ok($calm, 'Manager created');
isa_ok($calm, Manager, 'Manager class');

ok($calm->load_logic(Test => 'TestLogic'), 'Logic loaded');
ok(my $lm = $calm->logic('Test'), 'Manager returned Logic');
isa_ok($lm, 'Class::AbstractLogic::Base', 'Logic class');
