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
  
  describe 'simple routes' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/' do
          text('Hello, world')
        end

        get '/bye' do
          text('Good bye')
        end

        get '/ambiguous' do
          text('first route')
        end
        
        get '/ambiguous' do
          text('second route')
        end
      end
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

    it 'evaluates in the order routes appear' do
      get '/ambiguous'
      expect(last_response.body).to include('first route')      
    end

    describe 'missing route' do
      it "passes to downstream middleware if present"
      it "responds with 404 if last in chain" do
        get '/foobar'
        expect(last_response).to be_not_found
      end
    end

  end
  describe 'nested routes' do
    let(:app) do
      Class.new(Kawaii::Base) do
        context '/foo' do
          get '/' do
            text('Hello, world')
          end

          context '/bar' do
            get '/' do
              text('Foo bar')
            end
          end
        end
      end
    end

    it 'handles one level of nesting' do
      get '/foo/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Hello')
    end
    
    it 'handles two levels of nesting' do
      get '/foo/bar/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Foo')
    end    
  end
end


