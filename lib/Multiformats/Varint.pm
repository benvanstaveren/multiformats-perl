package 
    Multiformats::Varint {
    use strict;
    use warnings;
    use feature 'signatures';

    use Exporter 'import';
    our @EXPORT_OK = qw/varint_encode varint_decode varint_decode_raw/;

    sub decode($self, $value) {
        return varint_decode($value);
    }

    sub decode_raw($self, $value) {
        return varint_decode_raw($value);
    }

    sub encode($self, $value) {
        return varint_encode($value);
    }

    sub new($pkg) {
        return bless({}, $pkg);
    }

    # varint_encode, varint_decode_raw and varint_decode lifted from python multiformats https://github.com/hashberg-io/multiformats
    sub varint_encode($value) {
        die 'Multiformats::Varint::varint_encode: cannot encode negative values' unless $value >= 0;
        my @out = ();
        while(1) {
            my $next_byte = $value & 0b01111111;
            $value >>= 7;
            if($value > 0) {
                push(@out, $next_byte | 0b10000000);
            } else {
                push(@out, $next_byte);
                last;
            }
        }
        die 'Multiformats::Varint::varint_encode: encoded varint > 9 bytes' unless scalar(@out) <= 9;
        return wantarray 
            ? (pack('C*', @out), scalar(@out))
            : pack('C*', @out)
            ;
    }

    sub varint_decode($value) {
        my ($x, $read) = varint_decode_raw($value);
        die 'Multiformats::Varint::varint_decode: not all bytes used by encoding' if($read < length($value)); 
        return $x;
    }

    sub varint_decode_raw($value) {
        my $expect_next = 1;
        my $num_bytes_read = 0;
        my $x = 0;

        my @buf = unpack('C*', $value); # value is untouched, we'll need to lop the appropriate of bytes off
                                        # via the num_bytes_read later

        while($expect_next) {
            die 'Multiformats::Varint::varint_decode_raw: no next byte to read' if $num_bytes_read >= scalar(@buf);
            my $next_byte = $buf[$num_bytes_read];
            $x += ($next_byte & 0b01111111) << (7 * $num_bytes_read);
            $expect_next = ($next_byte >> 7 == 0b1) ? 1 : undef;
            $num_bytes_read++;
        }
    
        return wantarray
            ? ($x, $num_bytes_read)
            : $x;
    }
}

=pod

=head1 NAME

Multiformats::Varint - Varint decoding and encoding

=head1 SYNOPSIS

    use Multiformats::Varint qw/varint_encode varint_decode/;

    my $encoded = varint_encode(300); # \xAC\x02
    my $decoded = varint_decode("\xAC\x02"); # 300

=head1 FUNCTIONS 

=head2 varint_encode(...)

Encodes the given unsigned integer number to an unsigned Varint; returns a byte string. Will die if the varint is larger than the spec allows (>9 bytes).

=head2 varint_decode(...)

Decodes the given byte string to an unsigned integer. Will die if there are more bytes passed than required to decode a Varint. 

=head2 varint_decode_raw(...)

Like varint_decode, but will not die when there are bytes left in the input. 

When called in scalar context will return the decoded unsigned integer, when called in list context will return a list containing the unsigned integer, and the number of bytes used from the input. Does not alter the input value, so you will have to use C<substr> or some other mechanism to strip the used bytes out of the input value. 

=cut

1;
