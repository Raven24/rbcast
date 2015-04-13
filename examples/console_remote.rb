
#
# This program will try to discover your Chromecast via DNSSD/MDSN on your
# local network.
# Afterwards you will be able to control it with a few proof-of-concept
# command keys.
# It is recommended to start the script it with logger level set to debugging.
# For this just set an ENV like so:
#
#   `DEBUG=rbcast ruby console_remote.rb`
#
# You can then press a few registered keys to send commands to your Chromecast.
# Most notably:
#   * 'c'  ...  connect
#   * 'p'  ...  launch default media renderer
#   * ' ' (spacebar)  ...  load a hardcoded movie
#   * 'y'  ...  launch YouTube app
#   * 'v'  ...  load a hardcoded YT video
#   * 'q'  ...  disconnect
#
# You can quit this script like usual with [Ctrl]+'C'
# (There is no graceful disconnect or neat cleanup, I left that part as an
# excercise for the reader...)
#

require "dnssd"
require "rbcast"


class KeyboardControls < RBCast::Controllers::Base
  def initialize(ctx)  # overwrite
    @context = ctx
    @keys = {}

    @console_state = `stty -g`
    at_exit { `stty #{@console_state}` }
    `stty raw -echo -icanon isig opost onlcr`
  end

  def on_tick
    key = kbd_char
    return if key.empty?
    RBCast.info "#{key} pressed"
    return unless @keys.has_key?(key)

    @keys[key].call(@context) if @keys[key].respond_to?(:call)
  end

  def register(char, callback)
    @keys[char] = callback
  end

  def deregister(char)
    @keys.delete(char)
  end

  protected

  def kbd_char
    #state = `stty -g`
    #`stty raw -echo -icanon isig`
    begin
      STDIN.read_nonblock(1)
    rescue IO::WaitReadable
      ""
    end
  ensure
    #`stty #{state}`
  end
end

class YouTubeController < RBCast::Controllers::RequestResponse
  NAMESPACE = "urn:x-cast:com.google.youtube.mdx"

  def initialize(src, dest, sess)
    super src, dest
    @session_id = sess
  end

  def load(yt_id, opts={})
    msg = build_message(type: "flingVideo", data: {currentTime: 0, videoId: yt_id})
    _add_callbacks(msg, opts)
    queue msg
  end

  protected

  def build_message(data)
    msg = super
    msg.data["sessionId"] = @session_id
    msg
  end
end

class Chromecast
  APPID_MEDIAPLAYER = "CC1AD845"
  APPID_BACKDROP = "E8C28D3C"
  APPID_YOUTUBE = "233637DE"

  DEFAULT_SENDER = "sender-0"
  DEFAULT_DESTINATION = "receiver-0"

  def initialize(sock)
    @chan = RBCast::Channel.create sock
    @chan.connection = RBCast::Controllers::Connection.new DEFAULT_SENDER, DEFAULT_DESTINATION
    @chan.heartbeat = RBCast::Controllers::Heartbeat.new DEFAULT_SENDER, DEFAULT_DESTINATION
    @receiver = RBCast::Controllers::Receiver.new DEFAULT_SENDER, DEFAULT_DESTINATION
    @chan.receiver = @receiver
  end

  def keyboard_control!
    @kbd = KeyboardControls.new(self)
    @chan.add_controller @kbd

    @kbd.register("c", lambda { |context|
      @chan.connection.connect
    })

    @kbd.register("?", lambda { |context|
      @receiver.get_status
    })

    @kbd.register("q", lambda { |context|
      @chan.connection.disconnect
    })

    @kbd.register("b", lambda { |context|
      @receiver.launch(APPID_BACKDROP)
    })

    @kbd.register("y", lambda { |context|
      @receiver.launch(APPID_YOUTUBE, { success: lambda { |msg|
        app_info = msg.data["status"]["applications"].first
        trsp_id = app_info["transportId"]
        sess_id = app_info["sessionId"]

        context.start_youtube_ctrl(trsp_id, sess_id) if trsp_id && sess_id
      }})
    })

    @kbd.register("v", lambda { |context|
      @media.load("4a_lGfmW04Y")
    })

    @kbd.register("p", lambda { |context|
      @receiver.launch(APPID_MEDIAPLAYER, {
        success: lambda { |msg|
          app_info = msg.data["status"]["applications"].first
          trsp_id = app_info["transportId"]
          sess_id = app_info["sessionId"]

          context.start_media_ctrl(trsp_id, sess_id) if trsp_id && sess_id
        }
      })
    })

    @kbd.register(" ", lambda { |context|
      @media.load({ "streamType"=>"buffered", "contentType"=>"video/mp4",
                    "contentId"=>"http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4" }, {autoplay: true})
    })

    @kbd.register("s", lambda { |context|
      @media.stop
    })
  end

  def start_media_ctrl(trsp_id, sess_id)
    sender = _sender_id
    media_conn = RBCast::Controllers::Connection.new sender, trsp_id
    @chan.add_controller media_conn
    media_conn.connect

    @media = RBCast::Controllers::Media.new(sender, trsp_id, sess_id)
    @chan.add_controller(@media)
  end

  def start_youtube_ctrl(trsp_id, sess_id)
    sender = _sender_id
    yt_conn = RBCast::Controllers::Connection.new sender, trsp_id
    @chan.add_controller yt_conn
    yt_conn.connect

    @media = YouTubeController.new(sender, trsp_id, sess_id)
    @chan.add_controller(@media)
  end

  def init
    @chan.exec
  end

  protected

  def _sender_id
    "client-#{Time.now.to_i}"
  end
end


Thread.abort_on_exception = true
trap 'INT' do exit end
trap 'TERM' do exit end

@sock = nil

find = Thread.new do
  service = DNSSD::Service.browse '_googlecast._tcp.'
  service.each do |reply|
    r = reply.resolve
    puts r.inspect
    begin
      @sock = r.connect
    rescue SocketError => e
      RBCast.fatal "Unable to resolve DNSSD hostname! Please enable MDNS lookup." +
                   "see: https://wiki.archlinux.org/index.php/Avahi#Hostname_resolution"
      raise e
    end
    service.stop
  end
end
find.join

if @sock.nil?
  RBCast.fatal "No Chromecast found via DNSSD :("
  exit
end

cast = Chromecast.new @sock
cast.keyboard_control!
cast.init
