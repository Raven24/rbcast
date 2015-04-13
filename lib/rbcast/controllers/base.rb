
module RBCast::Controllers
  class Base
    attr_accessor :channel
    attr_writer :message_class

    def initialize(src, dest)
      @source_id = src
      @destination_id = dest
    end

    def build_message(data)
      msg = message_class.new
      msg.namespace = self.class::NAMESPACE
      msg.source_id = @source_id
      msg.destination_id = @destination_id
      msg.data.merge! data
      msg
    end

    def queue(msg)
      channel.queue msg
    end

    protected

    def message_class
      @message_class ||= RBCast::Message
    end
  end
end
