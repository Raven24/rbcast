module RBCast
  class Channel
    attr_reader :connection, :heartbeat, :receiver

    def self.create_from_address(ip, port)
      chan = Channel.new
      chan.create_from_address(ip, port)
      chan
    end

    def self.create(sock)
      chan = Channel.new
      chan.create sock
      chan
    end

    def initialize
      @send_queue = []
      @controllers = []
    end

    def create_from_address(ip, port)
      create(TCPSocket.new ip, port)
    end

    def create(sock)
      @socket = OpenSSL::SSL::SSLSocket.new sock
      @socket.connect

      RBCast.debug "socket opened"
    end

    def queue(msg)
      @send_queue << msg
    end

    def add_controller(ctrl)
      @controllers << ctrl
      ctrl.channel = self
      ctrl.on_add if ctrl.respond_to?(:on_add)
    end

    [:connection, :heartbeat, :receiver].each do |method|
      define_method :"#{method}=" do |ctrl|
        instance_variable_set(:"@#{method}", ctrl)
        add_controller(ctrl)
      end
    end

    def exec
      raise "Missing a required controller for [connection, heartbeat, receiver]" unless required_controllers_present?
      RBCast.debug "Starting controller loop..."
      commander = reader = writer = nil

      commander = Fiber.new do
        loop do
          _run_ctrl_callback(:on_tick)
          writer.resume unless @send_queue.empty?
          reader.resume
        end
      end

      reader = Fiber.new do
        loop do
          ready = IO.select([@socket], nil, nil, 0.75)
          Fiber.yield unless ready

          _read
          Fiber.yield
        end
      end

      writer = Fiber.new do
        loop do
          _write
          Fiber.yield
        end
      end

      commander.resume
    end

    protected

    def required_controllers_present?
      !@connection.nil? &&
      !@heartbeat.nil? &&
      !@receiver.nil?
    end

    def _run_ctrl_callback(cb, *params)
      @controllers.each do |ctrl|
        ctrl.public_send(cb, *params) if ctrl.respond_to?(cb)
      end
    end

    def _read
      begin
        len = @socket.read_nonblock(4).unpack("N").first
      rescue IO::WaitReadable
        return
      end
      msg = Message.new
      msg.read(@socket.read(len))
      RBCast.debug "<< #{msg.to_s}"

      _run_ctrl_callback(:on_message, msg)

      msg
    end

    def _write
      return if @send_queue.empty?
      msg = @send_queue.shift

      _run_ctrl_callback(:on_send, msg)

      RBCast.debug ">> #{msg.to_s}"
      @socket.write msg.write
      @socket.flush
    end
  end
end
