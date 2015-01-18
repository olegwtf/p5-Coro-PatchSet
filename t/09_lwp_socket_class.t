use strict;
use Test::More;
use Coro::LWP;
use Coro::PatchSet::LWP;

isa_ok('Net::HTTP', 'Coro::LWP::Socket');

done_testing;
