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

    # this map holds the various encodings and decodings
    use constant MB_MAP => [
        [ 'none',       "\0",   sub { return shift },                       sub { return shift }                        ],
        [ 'base32',     'b',    sub { return lc(encode_b32r(shift)) },      sub { return decode_b32r(uc(shift)) }       ],
        [ 'base32upper','B',    sub { return encode_b32r(shift) },          sub { return decode_b32r(shift) }           ],
        [ 'base36',     'k',    sub { return lc(encode_base36(shift)) },    sub { return decode_base36(shift) }         ],
        [ 'base58btc',  'z',    sub { return encode_b58b(shift) },          sub { return decode_b58b(shift) }           ],
    ];

    sub _map_by_tag($tag) {
        foreach my $entry (@{__PACKAGE__->MB_MAP}) {
            return $entry if($entry->[1] eq $tag);
        }
        return undef;
    }

    sub _map_by_name($name) {
        if(length($name) == 1) {
            return _map_by_tag($name);
        } else {
            foreach my $entry (@{__PACKAGE__->MB_MAP}) {
                return $entry if($entry->[0] eq $name);
            }
            return undef;
        }
    }

    sub multibase_decode($bytes) {
        # make sure it's actual bytes
        utf8::downgrade($bytes, 1);
        my $t = substr($bytes, 0, 1);
        if(my $e = _map_by_tag($t)) {
            my $decoded = $e->[3]->(substr($bytes, 1));
            return wantarray
                ? ($t, $decoded)
                : $decoded;
        } else {
            die 'unknown format ' . $t . ', ';
        }
    }

    sub multibase_encode($as, $bytes) {
        utf8::downgrade($bytes, 1);
        if(my $e = _map_by_name($as)) {
            my $encoded = $e->[1] . $e->[2]->($bytes);
            return $encoded;
        } else {
            die 'unknown format ' . $as . ', ';
        }
    }
}

=pod

=head1 NAME

Multiformats::Multibase - Multibase decoding and encoding

=head1 SYNOPSIS

    use Multiformats::Multibase qw/multibase_encode multibase_decode/;

    my $encoded = multibase_encode('base32', 'this will be base32 encoded');
    my $decoded = multibase_decode($encoded_string);

=head1 FUNCTIONS 

=head2 multibase_encode($base, $data_to_encode)

Encodes the given data with the given base. See below for supported bases.

=head2 multibase_decode($encoded_data);

Decodes the given data. When called in scalar context returns the decoded data. When called in list context returns a list containing the multibase tag and the decoded data

=head1 SUPPORTED BASES

=over

=item * base32

=item * base32upper

=item * base36

=item * base58btc

=back

=cut

1;
