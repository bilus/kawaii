require 'spec_helper'

describe 'MIME formats' do
  let(:app) do
    Class.new(Kawaii::Base) do
      get '/' do
        respond_to do |format|
          format.json { { foo: 'bar' } }
          format.html { 'Hello, world' }
        end
      end

      post '/params' do
        respond_to do |format|
          format.json { params }
        end
      end
    end
  end

  it 'responds with json' do
    header Rack::CONTENT_TYPE, 'application/json'
    get '/'
    expect(last_response.body).to eq '{"foo":"bar"}'
    expect(last_response.content_type).to eq 'application/json'
  end

  it 'responds with html' do
    get '/'
    expect(last_response.body).to eq 'Hello, world'
    expect(last_response.content_type).to eq 'text/html'
  end

  it 'parses json params' do
    header Rack::CONTENT_TYPE, 'application/json'
    post '/params', { foo: 'bar' }.to_json
    expect(last_response.body).to eq '{"foo":"bar"}'
  end
end
