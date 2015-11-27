module Kawaii
  # Implementation of nested routes generated via Router#context.
  #
  # @example A simple context
  #   context '/foo' do
  #     get '/bar' do
  #     end
  #   end
  #
  #   # It is a rough equivalent of:
  #
  #   ctx = RouteContext.new('/foo')
  #   ctx.get '/bar' do
  #   end
  #
  # @private
  class RouteContext
    include RoutingMethods
    include MethodChain

    # Create a {RouteContext} object.
    # @param path [String, Regexp, Matcher] any path specification which can be consumed by {Matcher.compile}
    def initialize(scope, path)
      self.parent_scope = scope
      super()
      @matcher = Matcher.compile(path, starts_with: true)
    end

    # Tries to match the context against a Rack environment.
    # @param env [Hash] Rack environment
    # @return [Route] matching route defined inside the context. Can be nil if no match found.
    def match(env)
      m = @matcher.match(env[Rack::PATH_INFO])
      # puts "RouteContext#match #{env[Rack::PATH_INFO].inspect} #{@matcher.inspect} #{m.inspect}"
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
end
