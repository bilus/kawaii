require 'spec_helper'

class HelloWorld < Kawaii::Controller
  def index
    'GET /users'
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

describe Kawaii::Controller do
  describe 'action matching' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/users/:id', 'hello_world#show'
        get '/foobar/:id', 'hello_world#foobar'
      end
    end

    it 'renders response' do
      get '/users/123'
      expect(last_response).to be_ok
      expect(last_response.body).to eq('GET /users/123')
    end

    it 'raises error if method not found' do
      expect { get '/foobar/123' }.to raise_error(NoMethodError)
    end
  end

  describe 'route'
  let(:app) do
    Class.new(Kawaii::Base) do
      route '/users', 'hello_world'
    end
  end

  it 'handles index' do
    get '/users/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('GET /users')
  end

  it 'handles show' do
    get '/users/123'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('GET /users/123')
  end

  it 'handles create' do
    post '/users/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('POST /users')
  end

  it 'handles update' do
    patch '/users/123'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('PATCH /users/123')
  end

  it 'handles destroy' do
    delete '/users/123'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('DELETE /users/123')
  end
end
