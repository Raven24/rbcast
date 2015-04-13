
module RBCast::Controllers
  class Connection < Base
    NAMESPACE = "urn:x-cast:com.google.cast.tp.connection"

    def on_message(msg)
      if msg.destination_id == @source_id && msg.data["type"] == "CLOSE"
        RBCast.warn "{#{@source_id}  <-->  #{@destination_id}} connection closed"
      end
    end

    def connect
      msg = build_message(type: "CONNECT")
      queue msg
      RBCast.info "{#{msg.source_id}  <-->  #{msg.destination_id}} connecting"
    end

    def disconnect
      msg = build_message(type: "CLOSE")
      queue msg
      RBCast.info "{#{msg.source_id}  <-->  #{msg.destination_id}} disconnecting"
    end
  end
end
