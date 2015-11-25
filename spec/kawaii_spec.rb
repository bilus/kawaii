require 'spec_helper'

def text(s)
  res = Rack::Response.new
  res.write(s)
  res.finish
end

describe Kawaii do
  
  it 'has a version number' do
    expect(Kawaii::VERSION).not_to be nil
  end
  
  describe 'routes' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/' do
          text('Hello, world')
        end

        get '/bye' do
          text('Good bye')
        end
      end.new
    end
    
    it 'renders a welcome page' do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Hello')    
    end

    it 'supports multiple routes' do
      get '/bye'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Good bye')
    end

    it '404s when no routes are matched' do
      get '/foobar'
      expect(last_response).to be_not_found
    end

    context 'missing route' do
      it "passes to downstream middleware if present"
      it "responds with 404 if last in chain"
    end
  end
end


