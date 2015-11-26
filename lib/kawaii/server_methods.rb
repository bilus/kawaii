module Kawaii
  # Mixins for starting a self-contained server. To be included in a class derived from {Base}.
  # @note At the moment hard-coded to use WEBrick.
  module ServerMethods
    # Starts serving the app.
    # @param port [Fixnum] port number to bind to
    def start!(port) # @todo TODO: Support other handlers http://www.rubydoc.info/github/rack/rack/Rack/Handler
      Rack::Handler.get("WEBrick").run(self, :Port => port) do |s|
        @server = s
        at_exit {  stop! }
        [:INT, :TERM].each do |signal|
          old = trap(signal) do
            stop!
            old.call if old.respond_to?(:call)
          end
        end
      end
    end

    # Stops serving the app.
    def stop!
      @server.stop if @server # NOTE: WEBrick-specific
    end

    # Returns true if the server is running.
    def running?
      !@server.nil?
    end
  end
end
