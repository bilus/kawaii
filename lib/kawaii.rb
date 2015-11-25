# require 'kawaii/version'
require 'rack'

module Kawaii
  class RouteBuilder
    def get(route, &block)
    end

    def build
      []
    end
  end

  class Route
    def initialize(*paths, &block)
      @path = File.join(*paths)
      @block = block
    end
    
    def matches?(request)
      puts "matches? #{@path} #{request.path_info}" 
      @path == request.path_info
    end

    def call(env)
      @block.call
    end
  end

  module ServerMethods
    def start! # TODO: Support other handlers http://www.rubydoc.info/github/rack/rack/Rack/Handler
      Rack::Handler.get("WEBrick").run(self, :Port => 8092) do |s| # TODO: Hard-coded port number.
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

    def stop!
      @server.stop if @server # NOTE: WEBrick-specific
    end

    def running?
      !@server.nil?
    end
  end

  class Base
    def initialize(downstream_app = nil) # TODO: Downstream app.
    end
    
    def call(env)
      matching = self.class.find_route(env) || not_found
      matching.call(env)
    end

    class << self
      include ServerMethods

      def namespace(path, &block)
        @parent_paths ||= []
        @parent_paths.push(path)
        block.call
      ensure
        @parent_paths.pop
      end
      
      def get(path, &block)
        add_route!(Rack::GET, path, &block) 
      end

      # Make it runnable via `run MyApp`.
      def call(env)
        @app ||= self.new
        @app.call(env)
      end
      
      def find_route(env)
        ensure_routes!
        request = Rack::Request.new(env)
        puts "find_route #{self.inspect} #{request.inspect}"
        @routes[request.request_method].find {|r| r.matches?(request)}
      end

      protected
      
      def add_route!(method, path, &block)
        puts "add_route! #{self.inspect}"
        ensure_routes!
        @routes[method] << Route.new(*@parent_paths, path, &block)
      end

      def ensure_routes!
        @routes ||= Hash.new {|h, k| h[k] = []}
      end
    end
    
    protected

    def not_found
      lambda { |env| [404, {Rack::CONTENT_TYPE => 'text/plain'}, ['Not found']] }
    end
  end

  class SingletonApp < Base
    class << self
      def maybe_start!
        if !running? && run_directly?
          # Give routes a chance to install and app to initialize.
          at_exit { start! unless $ERROR_INFO }
        end
      end

      protected

      def run_directly?
        c = caller_locations.map(&:path).find {|path| !skip_caller?(path)}
        File.identical?($PROGRAM_NAME, c)
      end

      def skip_caller?(path)
        File.identical?(path, __FILE__) ||
          path[/rubygems\/core_ext\/kernel_require\.rb$/]
      end
    end
  end
end

# Helpers to use directly in a .rb file without using a class inheriting from Kawaii::Base
#
# Example
#
# get '/' do
#    'Hello, world'
# end

class << self
  # TODO: Use define_method
  def get(*args, &block)
    Kawaii::SingletonApp.get(*args, &block)
  end

  def namespace(*args, &block)
    Kawaii::SingletonApp.namespace(*args, &block)
  end
end


# For self-contained execution without config.ru.
Kawaii::SingletonApp.maybe_start!


