class FirstApp < Kawaii::Base
  get '/' do
    res = Rack::Response.new
    res.write("First app")
    res.finish
  end
end
