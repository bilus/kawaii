module Kawaii
  # MVP controller. Define actions and map to them using regular routing
  # functions.
  #
  # @example Routing to controllers
  #  class HelloWorld < Kawaii::Controller
  #    def index
  #      'Hello, world'
  #    end
  #  end
  #
  #  get '/', 'hello_world#index'
  class Controller
    # Parameter [Hash] accessible in actions
    attr_reader :params
    # Rack::Request accessible in actions
    attr_reader :request

    # Creates a controller.
    def initialize(params, request)
      @params = params
      @request = request
    end
  end
end
