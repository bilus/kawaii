require 'kawaii'

class HelloWorld < Kawaii::Base
  get '/' do
    res = Rack::Response.new
    res.write("Hello, world")
    res.finish
  end
end

run HelloWorld
