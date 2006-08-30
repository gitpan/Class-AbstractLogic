#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 16;
use lib 't/lib';

use_ok('Class::AbstractLogic');

my $calm = Class::AbstractLogic::Manager->new(
    config => { TestLogic => { foo => 23 }} 
);
$calm->load_logic(Test => 'TestLogic');
$calm->load_logic(Foo  => 'Foo');

my $lm = $calm->logic('Test');
is($lm->simple(foo => 2)->result, 46, 'Simple Logic Action');

eval { $lm->needings(foo => 3) };
like($@, qr/bar/, 'Missing parameter raises Error');

eval { $lm->needings };
like($@, qr/bar/, 'All missing reported I');
like($@, qr/foo/, 'All missing reported II');

is($lm->need_w_string(foo => 10)->result, 33, 
    'Need Specification accepts string');

is($lm->needings(foo => 2, bar => 3)->result, 6, 
    'Success when all needed are provided');

is($lm->calling(foo => 10)->result, 100, 'Logic Action calling relative other');
is($lm->callwide(foo => 12)->result, 48, 'Logic Action calling absolute other');

is_deeply($lm->mult(list => [1,2,3], factor => 2)->result, [2,4,6],
    'Argument verification passes');

eval { $lm->mult(list => [1,2,3], factor => "foo") };
like($@, qr/factor/, 'Argument verification bites');

my $res = $lm->dies(foo => "Fnord");
ok(not($res), 'Exceptioned result object is false');
ok($res->is_failed, 'Exceptioned result object is failed');
is($res->value, undef, 'Exceptioned result value is undefined');
like($res->error, qr/Fnord/, 'Exceptioned result has correct error message');
is($res->key, 'fookey', 'Exceptioned result has correct key');
