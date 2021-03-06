module Kawaii
  # Creates context for execution of route handler block provided by the user
  # with {#params} and other objects.
  #
  # @example Route handler block
  #   get '/users/:id' do
  #     if params[:id] ...
  #   end
  class RouteHandler
    include MethodChain
    include RenderMethods
    include FormatMethods

    # Params based on request visible in the route handler scope.
    attr_reader :params
    # Rack::Request object visible in the route handler scope
    attr_reader :request

    # Creates a new RouteHandler wrapping a handler block.
    # @param path_params [Hash] named parameters from paths similar to
    #        /users/:id
    # @param block [Proc] the actual route handler
    def initialize(scope, path_params, &block)
      self.parent_scope = scope
      @path_params = path_params
      @block = block
    end

    # Invokes the handler as a normal Rack application.
    # @param env [Hash] Rack environment
    # @return [Array] Rack response array
    def call(env)
      @request = Rack::Request.new(env)
      @params = @path_params.merge(@request.params.symbolize_keys)
      process_response(instance_exec(self, params, request, &@block))
    end

    protected

    class ResponseError < RuntimeError; end

    def process_response(response)
      if response.is_a?(String) # @todo Use HtmlFormat
        [200,
         { Rack::CONTENT_TYPE => 'text/html',
           Rack::CONTENT_LENGTH => response.size.to_s },
         [response]]
      elsif response.is_a?(Array)
        response
      else
        fail ResponseError, "Unsupported handler response: #{response.inspect}"
      end
    end
  end
end
