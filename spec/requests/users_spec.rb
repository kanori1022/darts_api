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
    it 'creates user profile for current user' do
      # Use a non-persisted current user with a fresh id to avoid PK conflict
      new_current = User.new(id: 99999, firebase_uid: 'uid-new-user')
      stub_current_user(new_current)
      post '/users', params: { user: { name: 'Hanako', introduction: 'Hello' } }
      expect(response).to have_http_status(:created)
      expect(User.find(99999).name).to eq('Hanako')
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
