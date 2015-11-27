module Kawaii
  # Matching and resolution for a single route.
  class Route
    include MethodChain
    
    # Create a {Route} object.
    # @param path [String, Regexp, Matcher] any path specification which can be consumed by {Matcher.compile}
    # @param block [Proc] route handler
    def initialize(scope, path, &block)
      self.parent_scope = scope
      @matcher = Matcher.compile(path, full_match: true)
      @block = block
    end

    # Tries to match the route against a Rack environment.
    # @param env [Hash] Rack environment
    # @return [RouteHandler] a Rack application creating environment to run the route's handler block in on {RouteHandler#call}. Can be nil if no match found.
    def match(env)
      match = @matcher.match(env[Rack::PATH_INFO])
      # puts "Route#match #{@matcher} #{env[Rack::PATH_INFO]} #{match.inspect}"
      RouteHandler.new(self, match.params, &@block) if match
    end
  end
end
