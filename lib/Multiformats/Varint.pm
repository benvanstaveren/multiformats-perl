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
        return encode_varint($value);
    }

    sub new($pkg) {
        return bless({}, $pkg);
    }

    # varint_encode, varint_decode_raw and varint_decode lifted from python multiformats https://github.com/hashberg-io/multiformats
    sub varint_encode($value) {
        die 'PerlDS::Encoding::varint_encode: cannot encode negative values' unless $value >= 0;
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
        die 'PerlDS::Encoding::varint_encode: encoded varint > 9 bytes' unless scalar(@out) <= 9;
        return wantarray 
            ? (pack('C*', @out), scalar(@out))
            : pack('C*', @out)
            ;
    }

    sub varint_decode($value) {
        my ($x, $read) = varint_decode_raw($value);
        die 'PerlDS::Encoding::varint_decode: not all bytes used by encoding' if($read > length($value)); 
        return $x;
    }

    sub varint_decode_raw($value) {
        my $expect_next = 1;
        my $num_bytes_read = 0;
        my $x = 0;

        my @buf = unpack('C*', $value); # value is untouched, we'll need to lop the appropriate of bytes off
                                        # via the num_bytes_read later

        while($expect_next) {
            die 'PerlDS::Encoding::varint_decode: no next byte to read' if $num_bytes_read >= scalar(@buf);
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

1;
