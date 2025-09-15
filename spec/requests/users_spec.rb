require 'rails_helper'

RSpec.describe "Users API", type: :request do
  let!(:user) { User.create!(firebase_uid: 'uid-users', name: 'Taro') }

  describe 'GET /users' do
    it 'returns current user json when authorized' do
      stub_current_user(user)
      get '/users'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Taro')
      expect(json).to have_key('image')
    end

    it 'returns 401 when unauthorized' do
      get '/users'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /users' do
    it 'creates user profile without authentication' do
      # POST /users skips authentication, so no stub_current_user needed
      post '/users', params: { user: { name: 'Hanako', introduction: 'Hello' } }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('Hanako')
      expect(json['introduction']).to eq('Hello')
      # Verify user was actually created in database
      created_user = User.find_by(name: 'Hanako')
      expect(created_user).to be_present
      expect(created_user.introduction).to eq('Hello')
    end
  end

  describe 'PUT /users' do
    it 'updates current user' do
      stub_current_user(user)
      put '/users', params: { user: { name: 'Updated' } }
      expect(response).to have_http_status(:ok)
      expect(User.find(user.id).name).to eq('Updated')
    end
  end
end
