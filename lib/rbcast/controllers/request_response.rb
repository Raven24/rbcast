
module RBCast::Controllers
  class RequestResponse < Base
    @@_req_id = Time.now.to_i

    def initialize(src, dest)
      super
      @msgs = {}
    end

    def on_message(msg)
      req = @msgs.delete(msg.data["requestId"])
      return unless req

      if msg.data["type"] == "INVALID_REQUEST"
        req.error.call(msg) if req.error.respond_to?(:call)
      else
        req.success.call(msg) if req.success.respond_to?(:call)
      end
      req
    end

    protected

    def message_class
      @message_class ||= RBCast::CallbackMessage
    end

    def build_message(data)
      @@_req_id += 1

      msg = super
      msg.data["requestId"] = @@_req_id
      msg
    end

    def queue(msg)
      @msgs[msg.data["requestId"]] = msg
      super
    end

    def _add_callbacks(msg, opts)
      msg.success = opts[:success] if opts.key?(:success)
      msg.error = opts[:error] if opts.key?(:error)
    end
  end
end
