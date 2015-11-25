require 'kawaii'

get '/' do
  res = Rack::Response.new
  res.write("Hello, world")
  res.finish
end



