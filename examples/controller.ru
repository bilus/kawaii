require 'kawaii'

class HelloWorld < Kawaii::Controller
  def index
    @title = 'Hello, world'
    render('index.html.erb')
  end

  def show
    "GET /users/#{params[:id]}"
  end

  def create
    'POST /users'
  end

  def update
    "PATCH /users/#{params[:id]}"
  end

  def destroy
    "DELETE /users/#{params[:id]}"
  end
end


class App < Kawaii::Base
  route '/users/', :hello_world
end

run App
