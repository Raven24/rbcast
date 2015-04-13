module RBCast::ProtoBuf
  ENCODING_BYTES = Encoding::BINARY
  ENCODING_STRING = Encoding::UTF_8

  TYPE_VARINT           = 0
  TYPE_FIXED64          = 1
  TYPE_LENGTH_DELIMITED = 2
  TYPE_FIXED32          = 5

  module Key
    class << self
      def encode(idx, type)
        VarInt.encode((idx << 3) | type)
      end

      def decode(stream)
        bits = VarInt.decode(stream)
        type = bits & 0x07
        idx = bits >> 3
        [idx, type]
      end
    end
  end

  module VarInt
    class << self
      def encode(val)
        raise RangeError, "#{val} is negative" if val < 0
        return [val].pack('C') if val < 128
        bytes = []
        until val == 0
          bytes << (0x80 | (val & 0x7f))
          val >>= 7
        end
        bytes[-1] &= 0x7f
        bytes.pack('C*')
      end

      def decode(stream)
        val = index = 0
        begin
          byte = stream.readbyte
          val |= (byte & 0x7f) << (7 * index)
          index += 1
        end while (byte & 0x80).nonzero?
        val
      end
    end
  end

  module LenDelim
    class << self
      def encode(val, enc=ENCODING_STRING)
        bytes = val.dup
        bytes.force_encoding(enc)

        out = VarInt.encode(bytes.size)
        out << bytes
      end

      def decode(stream)
        len = VarInt.decode stream
        stream.read len
      end
    end
  end
end
