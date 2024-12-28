package 
    Multiformats::Multihash {
    use strict;
    use warnings;
    use feature 'signatures';

    use Exporter 'import';
    our @EXPORT_OK = qw/multihash_encode multihash_decode multihash_wrap multihash_unwrap/;

    use Digest::SHA qw/sha1 sha256 sha384 sha512/; # SHA2
    use Digest::SHA3 qw/sha3_224 sha3_384 sha3_256/;
    use Multiformats::Varint qw/varint_decode_raw varint_encode/;

    sub decode($self, $value) {
        return multihash_decode($value);
    }

    sub encode($self, $as, $value) {
        return multihash_encode($as, $value);
    }

    sub new($pkg) {
        return bless({}, $pkg);
    }

    # this map holds the various encodings and decodings
    use constant MULTIFORMAT_MAP => [
        [ 'identity',   0x00,     undef, sub { return shift } ],
        [ 'sha1',       0x11,     undef, sub { return sha1(shift) } ],
        [ 'sha2-256',   0x12,     undef, sub { return sha256(shift) } ],
        [ 'sha2-512',   0x13,     undef, sub { return sha512(shift) } ],
        [ 'sha3-384',   0x15,     undef, sub { return sha3_384(shift) } ],
        [ 'sha3-256',   0x16,     undef, sub { return sha3_256(shift) } ],
        [ 'sha3-224',   0x17,     undef, sub { return sha3_224(shift) } ],
        [ 'sha2-384',   0x20,     undef, sub { return sha_384(shift) } ],
    ];

    sub codecs { 
        return __PACKAGE__->MULTIFORMAT_MAP;
    }

    sub _map_by_tag($tag) {
        foreach my $entry (@{__PACKAGE__->MULTIFORMAT_MAP}) {
            return $entry if($entry->[1] == $tag);
        }
        return undef;
    }

    sub _map_by_name($name) {
        foreach my $entry (@{__PACKAGE__->MULTIFORMAT_MAP}) {
            return $entry if($entry->[0] eq $name);
        }
        return _map_by_tag($name);  
    }

    sub multihash_decode($bytes) {
        # make sure it's actual bytes
        utf8::downgrade($bytes, 1);

        my ($t, $bread_type) = varint_decode_raw($bytes);
        if(my $e = _map_by_tag($t)) {
            my ($l, $bread_len) = varint_decode_raw(substr($bytes, $bread_type));
            return substr($bytes, $bread_type + $bread_len); # there isn't any decoding since hashes are a one-way street so we just return the actual value
        } else {
            die 'unknown format ' . $t . ', ';
        }
    }

    sub multihash_unwrap($bytes) {
        utf8::downgrade($bytes, 1);

        my ($t, $bread_type) = varint_decode_raw($bytes);
        if(my $e = _map_by_tag($t)) {
            my ($l, $bread_len) = varint_decode_raw(substr($bytes, $bread_type));
            return wantarray
                ? ($e, substr($bytes, $bread_type + $bread_len))            # allows us to get the whole kit and kaboodle in one sitting 
                : substr($bytes, $bread_type + $bread_len)
        } else {
            die 'unknown format ' . $t . ', ';
        }
    }

    sub multihash_wrap($as, $bytes) {
        utf8::downgrade($bytes, 1);
        if(my $e = _map_by_name($as)) {
            return varint_encode($e->[1]) . varint_encode(length($bytes)) . $bytes;
        } else {
            die 'unknown format ' . $as . ', ';
        }
    }

    sub multihash_encode($as, $bytes) {
        utf8::downgrade($bytes, 1);
        if(my $e = _map_by_name($as)) {
            my $hash = $e->[3]->($bytes);
            return varint_encode($e->[1]) . varint_encode(length($hash)) . $hash;
        } else {
            die 'unknown format ' . $as . ', ';
        }
    }
}

1;
