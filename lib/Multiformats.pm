package Multiformats;
use strict;

# ABSTRACT: Implementation of several multiformats as per https://multiformats.io/ for use with ATprotocol

# VERSION

# this package exists purely as a little placeholder for various abstracts and versions; as well as some
# of the documentation

=pod

=head1 NAME

Multiformats - A bare-bones multiformat implementation

=head1 SYNOPSIS

    use Multiformats::Multibase qw/multibase_encode/;

    my $encoded = multibase_encode('base32upper', "my data that I would like encoded")

    my $multibase = Multiformats::Multibase->new;
    my $also_encoded = $multibase->encode('base32', "even more data I want encoded");

=head1 FUNCTIONAL/OO

Every module can be used either in an OO fashion or purely functional. Please see the various modules that make up this package for more details. 

=head1 CODEC SUPPORT

Not all codecs/hash functions/base encoders are supported, you will find out quick if they aren't because the various encode/decode functions will die when asked to encode or decode something with an unknown codec. CID only supports CIDv1, CIDv0 is not supported *at all*. 

=head1 SEE ALSO

=over

=item * L<Multiformats::CID> - CID handling

=item * L<Multiformats::Multibase> - Multibase encoding/decoding

=item * L<Multiformats::Multihash> - Multihash encoding/unwrapping

=item * L<Multiformats::Multicodec> - Multicodec wrapping/unwrapping

=item * L<Multiformats::Varint> - Varint encoding/decoding

=back 

=head1 AUTHOR

Ben van Staveren <madcat@cpan.org>, <ben@blockstackers.net> 

=head1 LICENSE

This package is licensed under the same terms as Perl itself. 

=cut

1;
