module Kawaii
  # Class used to implement a standalone Kawaii app generated with top-level
  # route helpers (e.g. monkey-patched onto the `main` object).
  #
  # This lets you create a .rb file containing just route definitions and run it
  # with `ruby` command.
  #
  # @example test.rb
  #   require 'kawaii'
  #
  #   get '/' do
  #     'Hello, world'
  #   end
  #
  # @example Running from command line
  #   ruby -r kawaii test.rb
  #   ...
  #
  class SingletonApp < Base
    class << self
      def maybe_start!(port)
        # Give routes a chance to install and app to initialize.
        at_exit { start!(port) unless $ERROR_INFO } if !running? && run_direct?
      end

      protected

      def run_direct?
        c = caller_locations.map(&:path).find { |path| !skip_caller?(path) }
        File.identical?($PROGRAM_NAME, c)
      end

      def skip_caller?(path)
        File.identical?(path, __FILE__) ||
          path[%r{rubygems/core_ext/kernel_require\.rb$}] ||
          path[%r{/kawaii.rb$}]
      end
    end
  end
end

# Helpers you use directly in a .rb file without using a class
# inheriting from {Base}.
#
# @example hello_world.rb
#   get '/' do
#      'Hello, world'
#   end
class << self
  include Kawaii::RoutingMethods

  def routes
    Kawaii::SingletonApp.routes # Add route handlers to {SingletonApp}
  end
end

# For self-contained execution without config.ru. See {SingletonApp} above.
Kawaii::SingletonApp.maybe_start!(8088) # @todo Hard-coded port number.
