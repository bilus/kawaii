require 'spec_helper'

class HelloWorld < Kawaii::Controller
  def index
    params[:id]
  end
end

describe "Kawaii::Controller" do
  describe 'action matching' do
    let(:app) do
      Class.new(Kawaii::Base) do
        get '/users/:id', 'hello_world#index'
      end
    end

    it 'renders response' do
      get '/users/123'
      expect(last_response).to be_ok
      expect(last_response.body).to eq("123")
    end
  end
end
