
module RBCast
  class Message
    PROTOCOL_VERSION = 0
    PAYLOAD_TYPE_STRING = 0
    PAYLOAD_TYPE_BINARY = 1

    attr_accessor :namespace, :source_id, :destination_id
    attr_reader :protocol_version, :payload_type, :data

    def initialize
      @protocol_version = PROTOCOL_VERSION
      @payload_type = PAYLOAD_TYPE_STRING
      @namespace = ""
      @data = {}
    end

    def type=(val)
      @data["type"] = val
    end

    def txt_data
      JSON.generate @data
    end

    def encode(io)
      io << RBCast::ProtoBuf::Key.encode(1, RBCast::ProtoBuf::TYPE_VARINT)           << RBCast::ProtoBuf::VarInt.encode(protocol_version)
      io << RBCast::ProtoBuf::Key.encode(2, RBCast::ProtoBuf::TYPE_LENGTH_DELIMITED) << RBCast::ProtoBuf::LenDelim.encode(source_id)
      io << RBCast::ProtoBuf::Key.encode(3, RBCast::ProtoBuf::TYPE_LENGTH_DELIMITED) << RBCast::ProtoBuf::LenDelim.encode(destination_id)
      io << RBCast::ProtoBuf::Key.encode(4, RBCast::ProtoBuf::TYPE_LENGTH_DELIMITED) << RBCast::ProtoBuf::LenDelim.encode(namespace)
      io << RBCast::ProtoBuf::Key.encode(5, RBCast::ProtoBuf::TYPE_VARINT)           << RBCast::ProtoBuf::VarInt.encode(payload_type)
      io << RBCast::ProtoBuf::Key.encode(6, RBCast::ProtoBuf::TYPE_LENGTH_DELIMITED) << RBCast::ProtoBuf::LenDelim.encode(txt_data, RBCast::ProtoBuf::ENCODING_BYTES)
    end

    def decode(io)
      until io.eof?
        idx, type = RBCast::ProtoBuf::Key.decode(io)
        case idx
        when 1 then
          @protocol_version = RBCast::ProtoBuf::VarInt.decode(io)
        when 2 then
          @source_id = RBCast::ProtoBuf::LenDelim.decode(io)
        when 3 then
          @destination_id = RBCast::ProtoBuf::LenDelim.decode(io)
        when 4 then
          @namespace = RBCast::ProtoBuf::LenDelim.decode(io)
        when 5 then
          @payload_type = RBCast::ProtoBuf::VarInt.decode(io)
        when 6 then
          @data = JSON.parse RBCast::ProtoBuf::LenDelim.decode(io)
        else
          raise "Unknown field"
        end
      end

    end

    def write(stream=nil)
      stream ||= ::StringIO.new
      stream.set_encoding RBCast::ProtoBuf::ENCODING_BYTES
      encode(stream)
      msg = stream.string

      [msg.size, msg].pack("NA%d" % msg.size)
    end

    def read(stream)
      stream = ::StringIO.new(stream) unless stream.is_a? IO
      decode(stream)
      @data
    end

    def to_s
      <<-END.gsub(/^ {8}/, '')
        MESSAGE v#{protocol_version}/t#{payload_type}/#{namespace}
           {#{source_id}  -->  #{destination_id}}
           #{txt_data}
      END
    end
  end
end
