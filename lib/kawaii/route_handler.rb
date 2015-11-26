module Kawaii
  # Creates context for execution of route handler block provided by the user
  # with {#params} and other objects.
  #
  # @example Route handler block
  #   get '/users/:id' do
  #     if params[:id] ...
  #   end
  class RouteHandler
    # Params based on request visible in the route handler scope.
    attr_reader :params
    # Rack::Request object visible in the route handler scope
    attr_reader :request

    # Creates a new RouteHandler wrapping a handler block.
    # @param path_params [Hash] named parameters from paths similar to /users/:id
    # @param block [Proc] the actual route handler
    def initialize(path_params, &block)
      @path_params = path_params
      @block = block
    end

    # Invokes the handler as a normal Rack application.
    # @param env [Hash] Rack environment
    # @return [Array] Rack response array
    def call(env)
      @request = Rack::Request.new(env)
      @params = @path_params.merge(@request.params.symbolize_keys)
      process_response(self.instance_eval(&@block))
    end

    protected

    def process_response(response)
      if response.is_a?(String)
        [200,
         {Rack::CONTENT_TYPE => 'text/html',
          Rack::CONTENT_LENGTH => response.size},
         [response]]
      else
        response
      end
    end
  end
end
