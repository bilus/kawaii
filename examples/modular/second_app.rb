class SecondApp < Kawaii::Base
  get '/' do
    res = Rack::Response.new
    res.write("Second app")
    res.finish
  end
end
