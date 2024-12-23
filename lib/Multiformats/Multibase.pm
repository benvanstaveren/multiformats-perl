package 
    Multiformats::Multibase {
    use strict;
    use warnings;
    use feature 'signatures';

    use Exporter 'import';
    our @EXPORT_OK = qw/multibase_encode multibase_decode/;

    use Crypt::Misc qw/encode_b58b decode_b58b encode_b32r decode_b32r/;
    use Math::Base36 qw/encode_base36 decode_base36/;

    sub decode($self, $value) {
        return multibase_decode($value);
    }

    sub encode($self, $as, $value) {
        return multibase_encode($as, $value);
    }

    sub new($pkg) {
        return bless({}, $pkg);
    }

    # these 2 maps map the actual encoding and decoding
    # to a subroutine that takes the to be decoded/encoded values as first argument
    # please note that only a few formats are implemented by default
    use constant MB_ENCODE_MAP => {
        'none'          =>  sub { return "\0" . shift },
        'base32'        =>  sub { return 'b' . encode_b32r(shift) },
        'base36'        =>  sub { return 'k' . encode_base36(shift) },
        'base58btc'     =>  sub { return 'z' . encode_b58b(shift) },
    };

    use constant MB_DECODE_MAP => {
        "\0"            =>  sub { return shift },
        'b'             =>  sub { return decode_b32r(shift) },
        'k'             =>  sub { return decode_base36(shift) },
        'z'             =>  sub { return decode_b58b(shift) },
    };

    sub multibase_decode($bytes) {
        my $t = substr($bytes, 0, 1);
        die 'unknown format ' . $t . ', ' unless exists MB_DECODE_MAP->{$t};
        return MB_DECODE_MAP->{$t}->(substr($bytes, 1));
    }

    sub multibase_encode($as, $bytes) {
        die 'unknown format ' . $as . ', ' unless exists MB_ENCODE_MAP->{$as};
        return MB_ENCODE_MAP->{$as}->($bytes);
    }
}

1;
