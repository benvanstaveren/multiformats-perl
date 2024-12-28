package 
    Multiformats::CID {

    use feature 'signatures';
    use Exporter 'import';
    our @EXPORT_OK = qw/cid/;
    use Multiformats::Varint qw/varint_decode_raw/;
    use Multiformats::Multicodec qw/multicodec_get_codec multicodec_wrap/;
    use Multiformats::Multibase qw/multibase_decode/;
    use Multiformats::Multihash qw/multihash_unwrap/;

    sub cid($bytes) {
        utf8::downgrade($bytes, 1);

        # so a v0 and v1 cid in binary should start with either 0x00 or 0x01 - if that isn't the case
        # assume we have a string cid
        if(substr($bytes, 0, 1) ne "\0" && substr($bytes, 0, 1) ne "\1") {
            my $binary = multibase_decode($bytes);
            return cid_from_binary($binary);
        } else {
            # binary
            return cid_from_binary($bytes);
        }
    }

    sub cid_from_binary($bytes) {
        utf8::downgrade($bytes, 1);
        my ($version, $bread)  = varint_decode_raw($bytes);
        die 'Unsupported CID version ', $version, ', ' unless $version == 1;

        my ($mc_codec, $bread_codec) = varint_decode_raw(substr($bytes, $bread));
        
        my $mc = Multiformats::Multicodec::_get_by_tag($mc_codec);

        # not sure what that codec tag does in here because it doesn't appear to do
        # anything short of encoding, well, nothing - the remaining data is the multihash 
        my ($mh, $hash) = multihash_unwrap(substr($bytes, $bread + $bread_codec));
       
        return Multiformats::CID::CIDv1->new(version => 1, codec => $mc->[0], hash_function => $mh->[0], hash => $hash);  
    }
}

package 
    Multiformats::CID::CIDv1 {
    use Mojo::Base -base, -signatures;
    use Multiformats::Multicodec qw/multicodec_wrap multicodec_unwrap/;
    use Multiformats::Multibase qw/multibase_encode/;
    use Multiformats::Varint qw/varint_encode/;
    use Multiformats::Multihash qw/multihash_wrap/;
    use overload bool => sub {1}, '""' => sub { shift->to_str }, fallback => 1;

    # note that the codecs are the tag values, not the names, we need to take this into account
    # in multibase_encode and multihash_encode
    has [qw/version codec hash_function hash/] => undef;

    sub to_str($self, $codec = 'base32') {
        return multibase_encode($codec, $self->to_bytes);
    }

    sub to_bytes($self) {
        my $hash    = multihash_wrap($self->hash_function, $self->hash);
        my $content = multicodec_wrap($self->codec, $hash);
        my $version = varint_encode($self->version);
        return $version . $content; 
    }
}

1;
    

