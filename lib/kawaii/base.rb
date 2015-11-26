module Kawaii
  # Base class for all Kawaii applications. Inherit from this class to create a modular
  # application.
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
    def initialize(downstream_app = nil) # @todo Downstream app.
    end

    # Instances of classes derived from [Kawaii::Base] are Rack applications.
    def call(env)
      matching = self.class.match(env) || not_found
      matching.call(env)
    end

    class << self
      include ServerMethods
      include RoutingMethods

      # Make it runnable via `run MyApp`.
      def call(env)
        @app ||= self.new
        @app.call(env)
      end
    end
    
    protected

    def not_found
      lambda { |env| [404, {Rack::CONTENT_TYPE => 'text/plain'}, ['Not found']] }
    end
  end  
end
