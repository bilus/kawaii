require 'spec_helper'
require 'rack/response'

describe Kawaii::Base do
  let(:app) { subject }

  
  
  before do
    app.routes do
      get '/' do
        res = Rack::Response.new
        res.write "Hello, world"
        res.finish
      end
    end
  end
  
  it 'renders a welcome page' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Hello')
    
  end
end


