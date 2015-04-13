# rbcast
Ruby Gem for controlling a Chromecast

The code is heavily inspired by [castnow](https://github.com/xat/castnow) (NodeJS) and [pychromecast](https://github.com/balloob/pychromecast) (Python).
It also contains a bare-bones implementation of ProtoBuf (with some bit-juggling code borrowed from the [protobuf gem](https://github.com/localshred/protobuf)).

The implementation uses Ruby Fibers to multiplex reading from/writing to the network socket.
Provided classes are pretty low-level but should allow access to the most important functions of a Chromecast device in your network.

See the examples directory for a proof-of-concept implementation of discovery via DNSSD/MDNS 
and also on how to inject your own code into the main event loop. There is also an example of how to "fling" videos to the YouTube app.

Have fun!
