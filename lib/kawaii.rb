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
    
    def matches?(env)
      puts "matches? #{@path} #{env[Rack::PATH_INFO]}" 
      @path == env[Rack::PATH_INFO]
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

  class RouteContext
    def initialize(*paths, app)
      @paths = paths
      @app = app
    end

    def get(path, &block)
      @app.add_route!(Rack::GET, *@paths, path, &block) 
    end

    def context(path, &block)
      RouteContext.new(*@paths, path, @app).instance_eval(&block)
    end
  end
  
  class Base
    def initialize(downstream_app = nil) # TODO: Downstream app.
    end
    
    def call(env)
      matching = self.class.match(env) || not_found
      matching.call(env)
    end

    class << self
      include ServerMethods

      def context(path, &block)
        RouteContext.new(path, self).instance_eval(&block)
      end
      
      def get(path, &block)
        add_route!(Rack::GET, path, &block) 
      end

      # Make it runnable via `run MyApp`.
      def call(env)
        @app ||= self.new
        @app.call(env)
      end
      
      def match(env)
        ensure_routes!
        puts "match #{self.inspect} #{env.inspect}"
        @routes[env[Rack::REQUEST_METHOD]].find {|r| r.matches?(env)}
      end

      def add_route!(method, *paths, &block)
        puts "add_route! #{self.inspect}"
        ensure_routes!
        @routes[method] << Route.new(*paths, &block)
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

  def context(*args, &block)
    Kawaii::SingletonApp.context(*args, &block)
  end
end


# For self-contained execution without config.ru.
Kawaii::SingletonApp.maybe_start!


