require 'spec_helper'

def text(s)
  s # String responses are supported directly.
end

describe Kawaii do
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

    it 'responds with 404 if no matching route' do
      get '/foobar'
      expect(last_response).to be_not_found
    end
  end

  describe 'nested routes' do
    let(:app) do
      Class.new(Kawaii::Base) do
        context '/foo/' do
          get '/' do
            text('Hello, world')
          end

          context '/bar/' do
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

  describe 'regex routes' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get %r{/|hello} do
          text('Hello, world')
        end

        context %r{/foo} do
          get %r{/bar} do
            text('bar')
          end
        end
      end
    end

    it 'renders a welcome page' do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Hello')
      get '/hello'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Hello')
    end

    it 'works with contexts' do
      get '/foo/bar'
      expect(last_response).to be_ok
      expect(last_response.body).to include('bar')
    end

    it 'responds with 404 if last in chain' do
      get '/whatever'
      expect(last_response).to be_not_found
    end
  end

  describe 'wildcard routes' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/hello/?' do
          text('Hello, world')
        end

        context '/foo/?' do
          get '/bar/?' do
            text('bar')
          end
        end

        get '/*' do
          text('whatever')
        end
      end
    end

    it 'renders a welcome page' do
      get '/hello/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Hello')
      get '/hello'
      expect(last_response).to be_ok
      expect(last_response.body).to include('Hello')
    end

    it 'works with contexts' do
      get '/foo/bar'
      expect(last_response).to be_ok
      expect(last_response.body).to include('bar')
      get '/foo/bar/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('bar')
    end

    it 'handles stars' do
      get '/whatever'
      expect(last_response).to be_ok
      expect(last_response.body).to include('whatever')
    end
  end

  describe 'custom route matchers' do
    class FooMatcher < Kawaii::Matcher
      def match(path)
        Kawaii::Match.new('') if path == '/foo'
      end
    end

    let(:app) do
      Class.new(Kawaii::Base) do
        get FooMatcher.new do
          text('foo')
        end

        get '/bar' do
          text('bar')
        end
      end
    end
    it 'matches paths starting from /foo' do
      get '/foo'
      expect(last_response.body).to include('foo')
      get '/bar'
      expect(last_response.body).to include('bar')
    end
  end

  describe 'parameters' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/users/:user_id/posts/:post_id/?' do
          text("#{params[:user_id]}-#{params[:post_id]}-#{params[:username]}")
        end
      end
    end

    it 'extracts paraters from path' do
      get '/users/123/posts/567'
      expect(last_response).to be_ok
      expect(last_response.body).to include('123-567')
    end

    it 'merges params from request' do
      get '/users/123/posts/567', username: 'username'
      expect(last_response).to be_ok
      expect(last_response.body).to include('username')
    end
  end

  describe 'request object' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/foo/?' do
          text(request.path_info)
        end
      end
    end

    it 'passes `request` object to route handler' do
      get '/foo'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('/foo')
    end
  end

  describe 'other http verbs' do
    let(:app) do
      Class.new(Kawaii::Base) do
        context '/foo' do
          post '/' do
            text('POST /foo/')
          end

          context '/bar' do
            put '/' do
              text('PUT /bar/')
            end

            post '/' do
              text('POST /bar/')
            end
          end
        end
      end
    end

    it 'handles one level of nesting' do
      get '/foo/'
      expect(last_response).to be_not_found

      post '/foo/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('POST /foo/')
    end

    it 'handles two levels of nesting' do
      get '/foo/bar/'
      expect(last_response).to be_not_found

      post '/foo/bar/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('POST /bar/')

      put '/foo/bar/'
      expect(last_response).to be_ok
      expect(last_response.body).to include('PUT /bar/')
    end
  end

  describe 'references to methods' do
    let(:app) do
      Class.new(Kawaii::Base) do
        def self.bar(params, _request) # Current limitation.
          params[:bar]
        end
        context '/ctx' do
          def foo(params, _request)
            params[:foo]
          end
          post '/foo/?', &:foo
          post '/bar/?', &:bar
        end
      end
    end

    it 'method defined at context scope' do
      post '/ctx/foo/', foo: 'foo'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('foo')
    end

    it 'method defined at class scope' do
      post '/ctx/bar/', bar: 'bar'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('bar')
    end
  end

  describe 'custom 404 handler' do
    let(:app) do
      Class.new(Kawaii::Base) do
        not_found do
          [404, { Rack::CONTENT_TYPE => 'text/plain' }, ['NOT FOUND']]
        end
      end
    end

    it 'uses the custom handler' do
      get '/'
      expect(last_response).to be_not_found
      expect(last_response.body).to eq('NOT FOUND')
    end
  end

  describe 'custom error handler' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/' do
          fail 'Ooops!'
        end
        on_error do |e|
          [500, { Rack::CONTENT_TYPE => 'text/plain' }, [e.to_s]]
        end
      end
    end

    it 'uses the custom handler' do
      get '/'
      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('Ooops!')
    end
  end
end
