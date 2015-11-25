require 'kawaii'


context '/foo' do
  get '/bar' do
    res = Rack::Response.new
    res.write('Nested routes')
    res.finish
  end

  get '/' do
    res = Rack::Response.new
    res.write('Hello')
    res.finish
  end    
end

