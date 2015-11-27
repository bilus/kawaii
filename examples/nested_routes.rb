require 'kawaii'

context '/foo' do
  get '/bar' do
    'Nested routes'
  end

  get '/' do
    'Hello'
  end
end
