
module RBCast::Controllers
  class Media < RequestResponse
    NAMESPACE = "urn:x-cast:com.google.cast.media"

    attr_reader :media_status

    def initialize(src, dest, sess)
      super src, dest
      @session_id = sess
      @media_status = {}
    end

    def on_message(msg)
      @media_status = msg.data["status"] if msg.data["type"] == "MEDIA_STATUS"
      super
    end

    def load(media, options={}, opts={})
      msg = build_message(type: "LOAD", media: media)

      _add_callbacks(msg, opts)
      succ = msg.success
      msg.success = lambda { |rsp|
        if rsp.data["type"] == "LOAD_FAILED"
          msg.error.call(rsp) if msg.error.respond_to?(:call)
        else
          succ.call(rsp) if succ.respond_to?(:call)
        end
      }

      msg.data["autoplay"] = options.fetch(:autoplay, false)
      msg.data["currentTime"] = options.fetch(:currentTime, 0)
      msg.data["activeTrackIds"] = options.fetch(:activeTrackIds, [])
      msg.data["customData"] = options.fetch(:customData, {})
      queue msg
    end

    def stop(opts={})
      msg = build_message_with_session(type: "STOP")
      _add_callbacks(msg, opts)
      queue msg
    end

    def play(opts={})
      msg = build_message_with_session(type: "PLAY")
      _add_callbacks(msg, opts)
      queue msg
    end

    def pause(opts={})
      msg = build_message_with_session(type: "PAUSE")
      _add_callbacks(msg, opts)
      queue msg
    end

    def seek(time, opts={})
      msg = build_message_with_session(type: "SEEK", currentTime: time)
      _add_callbacks(msg, opts)
      queue msg
    end

    protected

    def _media_sess_id
      @media_status.first["mediaSessionId"]
    end

    def build_message(data)
      msg = super
      msg.data["sessionId"] = @session_id
      msg
    end

    def build_message_with_session(data)
      msg = build_message(data)
      msg.data["mediaSessionId"] = _media_sess_id
      msg
    end
  end
end
