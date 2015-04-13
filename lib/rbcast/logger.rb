
module RBCast
  class EnvLogger
    def self.prepare
      l = Logger.new(STDOUT)
      l.level = (ENV['DEBUG'] =~ /rbcast/) ? Logger::DEBUG : Logger::WARN
      l.datetime_format = "%s.%L"
      l
    end
  end

  class << self
    extend Forwardable
    attr_accessor :logger

    def_delegators :@logger, :debug, :error, :fatal, :info, :unknown, :warn
  end
end

RBCast.logger = RBCast::EnvLogger.prepare
