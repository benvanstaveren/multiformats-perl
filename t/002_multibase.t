use Test::More;

use Multiformats::Multibase qw/multibase_encode multibase_decode/;

my $object = Multiformats::Multibase->new;

is(multibase_encode('base58btc', 'yes mani !'), 'z7paNL19xttacUY', 'imported encode: b58btc encodes properly');
is(multibase_decode('z7paNL19xttacUY'), 'yes mani !', 'imported decode: b58btc decodes properly');

is($object->encode('base58btc', 'yes mani !'), 'z7paNL19xttacUY', 'imported encode: b58btc encodes properly');
is($object->decode('z7paNL19xttacUY'), 'yes mani !', 'imported decode: b58btc decodes properly');

done_testing();
