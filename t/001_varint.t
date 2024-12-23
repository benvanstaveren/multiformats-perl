use Test::More;

use Multiformats::Varint qw/varint_encode varint_decode_raw varint_decode/;

my $object = Multiformats::Varint->new;

is(varint_encode(300), "\xAC\x02", 'non-wantarray encoding works');

my @o = varint_encode(300);

is($o[0], "\xAC\x02", 'wantarray encoding works');
is($o[1], 2, 'wantarray encoding returns proper bytes used');

is(varint_decode(pack('C*', 172, 2)), 300, 'non-wantarray decoding works');

my @d = varint_decode_raw(pack('C*', 172, 2));

is($d[0], 300, 'wantarray decoding works');
is($d[1], 2, 'wantarray decoding returns proper bytes used');

my $e = varint_encode(8675309);
is(varint_decode($e), 8675309, 'decoding encoded value works');

is($object->encode(300), "\xAC\x02", "OO encoding works");
is($object->decode_raw("\xAC\x02"), 300, "OO decoding works");

done_testing();
