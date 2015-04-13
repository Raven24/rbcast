
module RBCast::Controllers
  class Receiver < RequestResponse
    NAMESPACE = "urn:x-cast:com.google.cast.receiver"

    attr_reader :status

    def initialize(src, dest)
      super
      @status = {}
    end

    def on_message(msg)
      @status.merge!(msg.data["status"]) if msg.data["type"] == "RECEIVER_STATUS"
      super
    end

    def get_status(opts={})
      msg = build_message(type: "GET_STATUS")
      _add_callbacks(msg, opts)
      queue msg
    end

    def get_app_availability(app_id, opts={})
      msg = build_message(type: "GET_APP_AVAILABILITY", appId: [app_id])
      _add_callbacks(msg, opts)
      queue msg
    end

    def launch(app_id, opts={})
      msg = build_message(type: "LAUNCH", appId: app_id)
      _add_callbacks(msg, opts)
      queue msg
    end

    def stop(sess_id, opts={})
      msg = build_message(type: "STOP", sessionId: sess_id)
      _add_callbacks(msg, opts)
      queue msg
    end

    def set_volume(option, opts)
      msg = build_message(type: "SET_VOLUME", volume: option)
      _add_callbacks(msg, opts)
      queue msg
    end

    def mute(state, opts={})
      set_volume({muted: state}, opts)
    end

    def set_volume_level(lvl, opts={})
      set_volume({level: lvl}, opts)
    end
  end
end
