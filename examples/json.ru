require 'kawaii'
require 'rack'

class App < Kawaii::Base
  get '/' do
    respond_to do |format|
      format.json { {foo: :bar} }
      format.html { "Hello, world" }
    end
  end

  post '/' do
    respond_to do |format|
      format.json { params }
    end
  end
end

run App


