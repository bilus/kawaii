module Kawaii
  # Base class for all Kawaii applications. Inherit from this class to create
  # a modular application.
  #
  # @example my_app.rb
  #   require 'kawaii'
  #   class MyApp < Kawaii::Base
  #     get '/' do
  #       'Hello, world'
  #     end
  #   end
  #
  # @example config.ru
  #   require 'my_app.rb'
  #   run MyApp
  class Base
    def initialize(downstream_app = nil)
      @downstream_app = downstream_app
    end

    # Instances of classes derived from [Kawaii::Base] are Rack applications.
    def call(env)
      h = self.class.build(env)
      h.call(env)
    rescue => e
      self.class.handle_error(e)
    end

    class << self
      include ServerMethods
      include RoutingMethods

      # Define 404 handler. Has to return a valid Rack response.
      def not_found(&block)
        @not_found_handler = block
      end

      # Define an unhandled exception handler. Has to return a valid Rack
      # response.
      def on_error(&block)
        @error_handler = block
      end

      def build(env)
        h = match(env) || not_found_handler
        builder.run h
        builder.to_app
      end

      # Make it runnable via `run MyApp`.
      def call(env)
        @app ||= new
        @app.call(env)
      end

      def handle_error(e)
        handler = @error_handler || ->(ex) { fail ex }
        handler.call(e)
      end

      def use(middleware, *args, &block)
        builder.use(middleware, *args, &block)
      end

      def builder
        @builder ||= Rack::Builder.new
      end

      protected

      def not_found_handler
        @downstream_app ||
          @not_found_handler ||
          ->(_env) { text(404, 'Not found') }
      end

      def text(status, s)
        [status, { Rack::CONTENT_TYPE => 'text/plain' }, [s]]
      end
    end
  end
end
