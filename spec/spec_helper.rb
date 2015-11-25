$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'kawaii'
require 'rack/test'

RSpec.configure { |c| c.include Rack::Test::Methods }
