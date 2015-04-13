
module RBCast::Controllers
  class Heartbeat < Base
    NAMESPACE = "urn:x-cast:com.google.cast.tp.heartbeat"

    def on_message(msg)
      if msg.data["type"] == "PING"
        pong
      end
    end

    def pong
      msg = build_message(type: "PONG")
      queue msg
    end
  end
end
