require 'kawaii/version'
require 'rack/response'

module Kawaii
  class Base
    def call(env)
      res = Rack::Response.new
      res.write "Hello, world"
      res.finish
    end
  end
end
