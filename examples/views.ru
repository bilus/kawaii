require 'kawaii'

class Views < Kawaii::Base
  get '/' do
    @title = 'Hello, world'
    render('index.html.erb')
  end
end

run Views
