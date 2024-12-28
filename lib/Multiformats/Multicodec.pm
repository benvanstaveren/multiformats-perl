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

1;
