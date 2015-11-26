require 'kawaii/version'
require 'rack'

class Hash
  def update_keys
    result = self.class.new
    each_key do |key|
      result[yield(key)] = self[key]
    end
    result
  end

  def symbolize_keys
    update_keys(&:to_sym)
  end
end

module Kawaii

  class Match
    attr_reader :remaining_path
    attr_reader :params
    
    def initialize(remaining_path, params = {})
      @remaining_path = remaining_path
      @params = params
    end
  end

  class Matcher
    # Creates a matcher.
    def self.compile(x, options = {})
      # TODO: Make it extendable?
      matcher = if x.is_a?(String)
                  StringMatcher.new(x)
                elsif x.is_a?(Regexp)
                  RegexpMatcher.new(x)
                elsif x.is_a?(Matcher)
                  x
                else
                  raise RuntimeException, "#{x} is not a supported matcher"
                end
      if options[:full_match]
        FullMatcher.new(matcher) # Require path to fully match.
      else
        matcher
      end
    end
    
    # Returns Match if the beginning of path does match or nil if there is no match.
    # See `Match`.
    def match(path)
      # Implement in deriving classes.
    end
  end

  class StringMatcher
    def initialize(path)
      @rx = compile(path)
    end
    
    def match(path)
      m = path.match(@rx)
      puts "StringMatcher#match #{path} #{@rx} #{match_to_params(m) if m} #{m.to_a.inspect if m}"
      Match.new(remaining_path(path, m), match_to_params(m)) if m
    end

    protected

    def compile(path)
      prep_path = path.gsub('*', '.*').gsub(/\/\:([^\/]+)/, '/(?<\1>[^\/]+)')
      Regexp.new("^#{prep_path}")
    end

    def remaining_path(path, m)
      _, start = m.offset(0) # Whole match.
      path[start..-1]
    end
    
    def match_to_params(m)
      m.names.reduce({}) {|params, name| params[name.to_sym] = m[name]; params}
    end
  end

  class RegexpMatcher
    # TODO: Support parameters based on named capture groups.
    def initialize(rx)
      @rx = rx
    end

    def match(path)
      new_path = path.gsub(@rx, "")
      Match.new(new_path) if path != new_path
    end
  end

  class FullMatcher
    def initialize(matcher)
      @matcher = matcher
    end

    def match(path)
      m = @matcher.match(path)
      puts "FullMatcher#match #{path} #{m.remaining_path if m} #{@matcher.inspect}"
      m if m && m.remaining_path == ""
    end
  end

  class RouteHandler
    attr_reader :params
    attr_reader :request
    
    def initialize(path_params, &block)
      @path_params = path_params
      @block = block
    end

    def call(env)
      @request = Rack::Request.new(env)
      @params = @path_params.merge(@request.params.symbolize_keys)
      self.instance_eval(&@block)
    end
  end
  
  # A single route. Provides matching while behaving like a regular Rack app (Route#call).
  #
  class Route
    def initialize(path, &block)
      @matcher = Matcher.compile(path, full_match: true)
      @block = block
    end
    
    def match(env)
      match = @matcher.match(env[Rack::PATH_INFO])
      puts "Route#match #{@matcher} #{env[Rack::PATH_INFO]} #{match.inspect}"
      RouteHandler.new(match.params, &@block) if match
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
    HTTP_METHODS = ['GET'.freeze,
                    'POST'.freeze,
                    'PUT'.freeze,
                    'PATCH'.freeze,
                    'DELETE'.freeze,
                    'HEAD'.freeze,
                    'OPTIONS'.freeze,
                    'LINK'.freeze,
                    'UNLINK'.freeze,
                    'TRACE'.freeze]
    
    def initialize
      @routes = Hash.new {|h, k| h[k] = []}
    end

    def get(path, &block)
      add_route!(Rack::GET, Route.new(path, &block)) 
    end

    def context(path, &block)
      ctx = RouteContext.new(path)
      # TODO: Is there a better way to keep ordering of routes?
      # An alternative would be to enter each route in a context only once (with 'prefix' based
      # on containing contexts).
      # On the other hand, we're only doing that when compiling routes, further processing is
      # faster this way.
      ctx.instance_eval(&block)
      p self
      ctx.methods_used.each do |meth|
        add_route!(meth, ctx)
      end

    end
    
    def match(env)
      puts "Router#match #{env[Rack::PATH_INFO]} #{env[Rack::REQUEST_METHOD]} #{@routes[env[Rack::REQUEST_METHOD]]}"
      @routes[env[Rack::REQUEST_METHOD]].lazy.map {|r| r.match(env)}.find {|r| !r.nil?} # Lazy to avoid unnecessary calls to #match.
    end

    protected

    def methods_used
      @routes.keys
    end

    def add_route!(method, route)
      puts "add_route! #{method} #{route.inspect}"
      @routes[method] << route
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
      @matcher = Matcher.compile(path, starts_with: true)
    end

    def match(env)
      m = @matcher.match(env[Rack::PATH_INFO])
      puts "RouteContext#match #{env[Rack::PATH_INFO].inspect} #{@matcher.inspect} #{m.inspect}"

      super(env.merge(Rack::PATH_INFO => ensure_leading_slash(m.remaining_path))) if m
    end

    protected

    def ensure_leading_slash(path)
      if path.start_with?('/')
        path
      else
        '/' + path
      end
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


