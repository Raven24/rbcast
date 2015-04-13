
require File.expand_path("../lib/rbcast/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "rbcast"
  s.version     = RBCast::VERSION
  s.summary     = "Ruby Chromecast library"
  s.description = "Basic library for controlling a Chromecast in the local network"
  s.author      = "Florian Staudacher"
  s.email       = "florian_staudacher@yahoo.de"
  s.files       = Dir["{lib}/**/*.rb", "LICENSE"]
  s.homepage    = "https://github.com/Raven24/rbcast"
  s.license     = "MIT"
end
