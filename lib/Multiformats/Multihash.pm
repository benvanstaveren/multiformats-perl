package 
    Multiformats::Multihash {
    use strict;
    use warnings;
    use feature 'signatures';

    use Exporter 'import';
    our @EXPORT_OK = qw/multihash_encode multihash_decode multihash_wrap multihash_unwrap multihash_unwrap_stream/;

    use Digest::SHA qw/sha1 sha256 sha384 sha512/; # SHA2
    use Digest::SHA3 qw/sha3_224 sha3_384 sha3_256/;
    use Multiformats::Varint qw/varint_decode_raw varint_encode varint_decode_stream/;

    sub decode($self, $value) {
        return multihash_decode($value);
    }

    sub encode($self, $as, $value) {
        return multihash_encode($as, $value);
    }

    sub wrap($self, $as, $value) {
        return multihash_wrap($as, $value);
    }

    sub unwrap($self, $value) {
        return multihash_unwrap($value);
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

    sub multihash_unwrap_stream($stream) {
        my ($t, $bread_type) = varint_decode_stream($stream);
        if(my $e = _map_by_tag($t)) {
            my ($l, $bread_len) = varint_decode_stream($stream);
            my $buf;
            $stream->read($buf, $l); # the raw digest 
            return wantarray
                ? ([$e->[0], $e->[1] ], $buf)            # allows us to get the whole kit and kaboodle in one sitting 
                : $buf
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
                ? ([$e->[0], $e->[1] ], substr($bytes, $bread_type + $bread_len))            # allows us to get the whole kit and kaboodle in one sitting 
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

=pod

=head1 NAME

Multiformats::Multihash - Multihash encoding/decoding/wrapping

=head1 SYNOPSIS

    use Multiformats::Multihash qw/multihash_encode multihash_decode multihash_unwrap multihash_wrap/;
    my $data = '...'; 

    my $encoded = multihash_encode('sha2-256', $data); 

    my $hash = Digest::SHA::sha256($data);
    
    my $encoded_also = multihash_wrap('sha2-256', $hash); 

=head1 FUNCTIONS

=head2 multihash_encode($hash_function, $data)

Hashes the data with the given hash function, and encodes the result into a Multihash  

=head2 multihash_decode($data)

Parses the used hash function and hash length for validity, and returns the original raw hash 

=head2 multihash_unwrap($data)

Acts similar to C<multihash_decode> when called in scalar context, but when called in list context returns a list containing the encoding/decoding array and the raw hash. The decoding arrayref has the hash function name as first element, and the hash function tag value as the second value. 

    my ($encoding, $raw_hash) = multihash_unwrap($data)
    
    $encoding->[0]; # e.g. 'sha2-256'
    $encoding->[1]; # e.g. 0x12

=head2 multihash_wrap($hash_function, $data)

Acts similar to C<multihash_encode> but assumes the data passed is already a raw hash so does not digest it before encoding to a Multihash

=head1 SUPPORTED HASHES

=over

=item * identity

=item * sha1

=item * sha2-256

=item * sha2-512

=item * sha3-384

=item * sha3-256

=item * sha3-224

=item * sha2-384

=back

=cut

1;
