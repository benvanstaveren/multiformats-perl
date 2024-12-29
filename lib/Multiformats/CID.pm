package 
    Multiformats::CID {

    use feature 'signatures';
    use feature 'isa';
    use Exporter 'import';
    our @EXPORT_OK = qw/cid/;
    use Multiformats::Varint qw/varint_decode_raw varint_decode_stream/;
    use Multiformats::Multicodec qw/multicodec_get_codec multicodec_wrap/;
    use Multiformats::Multibase qw/multibase_decode/;
    use Multiformats::Multihash qw/multihash_unwrap multihash_unwrap_stream/;

    sub cid($bytes) {
        if(ref($bytes) && ($bytes isa 'IO::Handle' && $bytes isa 'IO::Seekable')) {
            return cid_from_stream($bytes);
        } else {
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
    }

    sub cid_from_stream($stream) {
        my ($version, $bread) = varint_decode_stream($stream);
        die 'Unsupported CID version ', $version, ', ' unless $version == 1;
        my ($mc_codec, $bread_codec) = varint_decode_stream($stream);
        my $mc = Multiformats::Multicodec::_get_by_tag($mc_codec);
        my ($mh, $hash) = multihash_unwrap_stream($stream);
        return Multiformats::CID::CIDv1->new(version => 1, codec => $mc->[0], hash_function => $mh->[0], hash => $hash);  
    }

    sub cid_from_binary($bytes) {
        utf8::downgrade($bytes, 1);
        my ($version, $bread)  = varint_decode_raw($bytes);
        die 'Unsupported CID version ', $version, ', ' unless $version == 1;

        my ($mc_codec, $bread_codec) = varint_decode_raw(substr($bytes, $bread));
        
        my $mc = Multiformats::Multicodec::_get_by_tag($mc_codec);

        # not sure what that codec tag does in here because it doesn't appear to do
        # anything - it's not encoding the remainder, so... what's it do Frank?!
        my ($mh, $hash) = multihash_unwrap(substr($bytes, $bread + $bread_codec));
        return Multiformats::CID::CIDv1->new(version => 1, codec => $mc->[0], hash_function => $mh->[0], hash => $hash);  
    }
}

package 
    Multiformats::CID::CIDv1 {
    use Mojo::Base -base, -signatures;
    use Multiformats::Multicodec qw/multicodec_wrap/;
    use Multiformats::Multibase qw/multibase_encode/;
    use Multiformats::Varint qw/varint_encode/;
    use Multiformats::Multihash qw/multihash_wrap/;
    use overload bool => sub {1}, '""' => sub { shift->to_str }, fallback => 1;

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

=pod

=head1 NAME

Multiformats::CID - CID handling

=head1 SYNOPSIS

    use Multiformats::CID qw/cid/;

    # can use either the stringified representation or the raw binary representation
    my $cid = cid('bafyreigngt2aslhuh7jbgpuliep4v4uvlantdmew2ojr7u3upknttpvqxa');

=head1 FUNCTIONS

=head2 cid(...) 

When given a string representation or binary representation of a CID will decode the version, codec, hash function, and hash value used and will return those wrapped in a C<Multiformats::CID::CIDv1> object.

=head1 CIDv1 Object

This object wraps a CID and has the following attributes and methods

=head2 ATTRIBUTES

=head3 version
    
Returns the version of the CID (always 1)

=head3 codec

Returns the name of the multibase codec

=head3 hash_function

Returns the name of the hash function used

=head3 hash

Returns the binary hash (obtained via the hash function)

=head2 METHODS

=head3 to_str() 

Returns the stringified version of the CID. The CID object itself is overloaded to return this when used in string context. 

=head3 to_bytes()

Returns the binary representation of the CID. 
   
=cut 

1;
    

