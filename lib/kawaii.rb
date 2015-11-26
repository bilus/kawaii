# require 'kawaii/version'
require 'rack'

module Kawaii
  # A single route. Provides matching while behaving like a regular Rack app (Route#call).
  #
  class Route
    def initialize(path, &block)
      @path = path
      @block = block
    end
    
    def match(env)
      puts "Route#match #{@path} #{env[Rack::PATH_INFO]}" 
      self if @path == env[Rack::PATH_INFO]
    end

    def call(env)
      @block.call
    end
  end

  # Mixins for starting a self-contained server.
  # At the moment hard-coded to use WEBrick.
  #
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

  # Core route-building and matching.
  #
  # These functions can be used both in a class inheriting from Kawaii::Base and with `main` object.
  #
  # Example
  #
  # class MyApp < Kawaii::Base
  #   get '/' do
  #     'Hello, world'
  #   end
  # end
  #
  # or
  #
  # get '/' do
  #   'Hello, world'
  # end
  #
  class Router
    ANY_METHOD = :any
    
    def initialize
      @routes = Hash.new {|h, k| h[k] = []}
    end

    def get(path, &block)
      add_route!(Rack::GET, Route.new(path, &block)) 
    end

    def context(path, &block)
      ctx = RouteContext.new(path)
      add_route!(Router::ANY_METHOD, ctx)
      ctx.instance_eval(&block)
    end
    
    def match(env)
      all_routes = @routes[env[Rack::REQUEST_METHOD]] + @routes[ANY_METHOD] # TODO: Performance.
      all_routes.lazy.map {|r| r.match(env)}.find {|r| !r.nil?} # Lazy to avoid unnecessary calls to #match.
    end

    protected

    def add_route!(method, router)
      puts "add_route! #{self.inspect}"
      @routes[method] << router 
    end
  end

  # Implementation of nested routes generated via Router#context.
  #
  # Example
  #
  # context '/foo' do
  #   get '/bar' do
  #   end
  # end
  #
  # Is a rough equivalent of:
  #
  # ctx = RouteContext.new('/foo')
  # ctx.get '/bar' do
  # end
  #
  class RouteContext < Router
    def initialize(path)
      super()
      @path = path
    end

    def match(env)
      puts "RouteContext#match #{self.inspect} #{env.inspect}"
      remaining_path = match_path(env[Rack::PATH_INFO])
      if remaining_path
        super(env.merge(Rack::PATH_INFO => remaining_path))
      end
    end

    def match_path(path_info)
      compiled_path = Regexp.new("^#{@path}(.*)")
      path_info.match(compiled_path).to_a.last
    end
  end

  # Base class for all Kawaii applications. Inherit from this class to create a modular
  # application.
  #
  # Example
  #
  # class MyApp < Kawaii::Base
  #   get '/' do
  #     'Hello, world'
  #   end
  # end
  #
  class Base
    def initialize(downstream_app = nil) # TODO: Downstream app.
    end
    
    def call(env)
      matching = self.class.match(env) || not_found
      matching.call(env)
    end

    class << self
      include ServerMethods

      # TODO: Generate dynamically.
      def context(path, &block)
        router.context(path, &block)
      end
      
      def get(path, &block)
        router.get(path, &block)
      end

      def router
        @router ||= Router.new
      end


      # Make it runnable via `run MyApp`.
      def call(env)
        @app ||= self.new
        @app.call(env)
      end
      
      def match(env)
        puts "Base#match #{self.inspect} #{env.inspect}"
        router.match(env)
      end
    end
    
    protected

    def not_found
      lambda { |env| [404, {Rack::CONTENT_TYPE => 'text/plain'}, ['Not found']] }
    end
  end

  # Class used to implement a standalone Kawaii app generated with top-level route helpers
  # (e.g. monkey-patched onto the `main` object).
  #
  # This lets you create a .rb file containing just route definitions and run it with ruby command.
  #
  # Example (test.rb)
  #
  # require 'kawaii'
  #
  # get '/' do
  #   'Hello, world'
  # end
  #
  # $ ruby -r kawaii test.rb 
  # [2015-11-25 23:36:28] INFO  WEBrick 1.3.1
  # [2015-11-25 23:36:28] INFO  ruby 2.1.2 (2014-05-08) [x86_64-darwin13.0]
  # [2015-11-25 23:36:28] INFO  WEBrick::HTTPServer#start: pid=43750 port=8092
  #
  # See examples/hello_world.rb and 'Running examples' in the Readme.
  # 
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

# Helpers you use directly in a .rb file without using a class inheriting from Kawaii::Base
#
# Example
#
# get '/' do
#    'Hello, world'
# end
#
class << self
  # TODO: Use define_method
  def get(*args, &block)
    Kawaii::SingletonApp.get(*args, &block)
  end

  def context(*args, &block)
    Kawaii::SingletonApp.context(*args, &block)
  end
end


# For self-contained execution without config.ru. See the description of `SingletonApp` above.
#
Kawaii::SingletonApp.maybe_start!


