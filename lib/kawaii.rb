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
    def initialize(path, &block)
      @path = path
      @block = block
    end
    
    def matches?(request)
      puts "matches? #{@path} #{request.path}" 
      @path == request.path
    end

    def call(env)
      @block.call
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
      def get(path, &block)
        add_route!(Rack::GET, path, &block) 
      end

      def find_route(env)
        ensure_routes!
        request = Rack::Request.new(env)
        puts "find_route #{request.inspect}"
        @routes[request.request_method].find {|r| r.matches?(request)}
      end

      def add_route!(method, path, &block)
        ensure_routes!
        @routes[method] << Route.new(path, &block)
      end

      def ensure_routes!
        @routes ||= Hash.new {|h, k| h[k] = []}
      end

      # Make it runnable via `run MyApp`.
      def call(env)
        @app ||= new
        @app.call(env)
      end
    end
    
    protected

    def not_found
      lambda { |env| [404, {Rack::CONTENT_TYPE => 'text/plain'}, ['Not found']] }
    end
  end
end

