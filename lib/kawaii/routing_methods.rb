module Kawaii
  # Core route-building and matching.
  #
  # These functions can be used both in a class inheriting from {Base} and in file scope.
  #
  # @example Using a class deriving from {Base}
  #   class MyApp < Kawaii::Base
  #     get '/' do
  #       'Hello, world'
  #     end
  #   end
  #
  # @example Using top-level (source file scope) route definitions
  #   get '/' do
  #     'Hello, world'
  #   end
  module RoutingMethods
    
    # @!macro [attach] add_http_method
    #   @method $1(path, &block)
    #   Route handler for $1 HTTP method
    #   @param path [String, Regexp, Matcher] any path specification which can be consumed by {Matcher.compile}
    #   @param block the route handler
    #   @yield to the given block
    # @note Supported HTTP verbs based on https://github.com/rack/rack/blob/master/lib/rack.rb#L48
    def self.add_http_method(meth)
      define_method(meth) do |path, &block|
        add_route!(meth.to_s.upcase, Route.new(self, path, &block)) 
      end
    end

    add_http_method :get
    add_http_method :post
    add_http_method :put
    add_http_method :patch
    add_http_method :delete
    add_http_method :head
    add_http_method :options
    add_http_method :link
    add_http_method :unlink
    add_http_method :trace
    # Note: Have to generate them individually due to yard limitations.

    
    # Create a context for route nesting.
    #
    #   @param path [String, Regexp, Matcher] any path specification which can be consumed by {Matcher.compile}
    #   @param block the route handler
    #   @yield to the given block    
    #
    # @example A simple context
    #   context '/foo' do
    #     get '/bar' do
    #     end
    #   end
    def context(path, &block)
      ctx = RouteContext.new(self, path)
      # @todo Is there a better way to keep ordering of routes?
      # An alternative would be to enter each route in a context only once (with 'prefix' based
      # on containing contexts).
      # On the other hand, we're only doing that when compiling routes, further processing is
      # faster this way.
      ctx.instance_eval(&block)
      ctx.methods_used.each do |meth|
        add_route!(meth, ctx)
      end
    end

    # Tries to match against a Rack environment.
    # @param env [Hash] Rack environment
    # @return [Route] matching route. Can be nil if no match found.
    def match(env)
      # puts "Router#match #{env[Rack::PATH_INFO]} #{env[Rack::REQUEST_METHOD]} #{@routes[env[Rack::REQUEST_METHOD]]}"
      routes[env[Rack::REQUEST_METHOD]].lazy.map {|r| r.match(env)}.find {|r| !r.nil?} # Lazy to avoid unnecessary calls to #match.
    end

    # Returns a list of HTTP methods used by the routes (including nested routes).
    # @return [Array<String>] example ["GET", "POST"]
    def methods_used
      routes.keys
    end

    protected

    def routes
      @routes ||= Hash.new {|h, k| h[k] = []}
    end

    def add_route!(method, route)
      # puts "add_route! #{method} #{route.inspect}"
      routes[method] << route
    end
  end  
end
