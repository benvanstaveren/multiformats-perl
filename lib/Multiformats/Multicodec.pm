package 
    Multiformats::Multicodec {
    use strict;
    use warnings;
    use feature 'signatures';
    use Multiformats::Varint qw/varint_decode_raw varint_encode/;

    use Exporter 'import';
    our @EXPORT_OK = qw/multicodec_wrap multicodec_unwrap multicodec_get_codec/;

    use constant MULTICODEC_MAP => [
        [ 'raw',  0x55 ],
        [ 'dag-cbor', 0x71 ],
    ];

    sub wrap($self, $as, $value) {
        return multihash_wrap($as, $value);
    }

    sub unwrap($self,  $value) {
        return multihash_unwrap($value);
    }

    sub get_codec($self, $value) {
        return multihash_codec($value);
    }

    sub new($pkg) {
        return bless({}, $pkg);
    }

    sub _get_by_name($as) {
        foreach my $entry (@{__PACKAGE__->MULTICODEC_MAP}) {
            return $entry if($entry->[0] eq $as);
        }
        return _get_by_tag($as);
    }

    sub _get_by_tag($tag) {
        foreach my $entry (@{__PACKAGE__->MULTICODEC_MAP}) {
            return $entry if($entry->[1] == $tag);
        }
        return undef;
    }

    sub multicodec_wrap($as, $value) {
        utf8::downgrade($value, 1);
        if(my $e = _get_by_name($as)) {
            my $id = varint_encode($e->[1]);
            return $id . $value; 
        } else {
            die 'Unsupported multicodec type ', $as, ', ';
        }
    }

    sub multicodec_unwrap($value) {
        utf8::downgrade($value, 1);
        my ($id, $bytes) = varint_decode_raw($value);
        return substr($value, $bytes);

    }

    sub multicodec_get_codec($value) {
        utf8::downgrade($value, 1);
        my ($id, $bytes) = varint_decode_raw($value);
        if(my $e = _get_by_tag($id)) {
            return $e; 
        } else {
            die 'Unsupported multicodec type ', $id, ', ';
        }
    }
}

=pod

=head1 NAME

Multiformats::Multicodec - Multicodec encoding/decoding/wrapping

=head1 SYNOPSIS

    use Multiformats::Multicodec qw/multicodec_get_codec multicodec_unwrap multicodec_wrap/;

    my $data = '...'; 

    my $encoded = multicodec_wrap('dag-cbor', $data);
    my $decoded = multicodec_unwrap($encoded); 

    my $codec = multicodec_get_codec($encoded);

    $codec->[0]; # dag-cbor
    $codec->[1]; # 0x71
    

=head1 FUNCTIONS

=head2 multicodec_wrap($codec, $data);

Wraps the given data with the proper multicodec tag 

=head2 multicodec_unwrap($data)

Unwraps the given data and returns the original raw data

=head2 multicodec_get_codec($data)

Returns an arrayref containing the codec information that the data is encoded with. First item in the arrayref is the codec name, second item is the codec tag value.

=head1 SUPPORTED CODECS

=over

=item * raw

=item * dag-cbor

=back

=cut

1;
