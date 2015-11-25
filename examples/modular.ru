require 'kawaii'
require_relative 'modular/first_app'
require_relative 'modular/second_app'

map '/first' do
  run FirstApp
end

map '/second' do
  run SecondApp
end
