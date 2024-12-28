use Test::More;

use_ok('Multiformats::CID');

my $binary = "\1q\22 |\b\217\356\37\274\0\216H\230\361\"\234\4\243ZFc\225`\26k\316\$\363\tfQ\234\307\3550";

my $cid = Multiformats::CID::cid($binary); 

is(ref($cid), 'Multiformats::CID::CIDv1', 'cid returns proper object');

my $str = $cid->to_str; 

my $cid2 = Multiformats::CID::cid($str); 

is(ref($cid2), 'Multiformats::CID::CIDv1', 'cid returns proper object for string cid');

is($cid2->hash, $cid->hash, 'hashes match');



done_testing();
