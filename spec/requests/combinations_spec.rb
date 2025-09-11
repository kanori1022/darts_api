require 'rails_helper'

RSpec.describe "Combinations API", type: :request do
  let!(:user) { User.create!(firebase_uid: 'uid1') }
  let!(:other) { User.create!(firebase_uid: 'uid2') }

  describe 'GET /combinations' do
    it 'returns popular list with pagination' do
      Combination.create!(user: user, title: 'A')
      get '/combinations', params: { limit: 5, offset: 0 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['combinations']).to be_a(Array)
      expect(json['pagination']).to include('total_pages')
    end
  end

  describe 'GET /combinations/newest' do
    it 'returns newest list' do
      Combination.create!(user: user, title: 'A')
      get '/combinations/newest'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /combinations/search' do
    it 'filters by keyword and username' do
      Combination.create!(user: user, title: 'Flight X', description: 'desc')
      get '/combinations/search', params: { searchWord: 'Flight', username: '' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['combinations'].first['title']).to include('Flight')
    end
  end

  describe 'POST /combinations' do
    it 'creates a combination for current user' do
      stub_current_user(user)
      post '/combinations', params: { combination: { title: 'New', tags: %w[one two] } }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['tags']).to match_array(%w[one two])
    end
  end

  describe 'PUT /combinations/:id' do
    it 'forbids editing others combinations' do
      c = Combination.create!(user: other, title: 'X')
      stub_current_user(user)
      put "/combinations/#{c.id}", params: { combination: { title: 'Edit' } }
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates own combination' do
      c = Combination.create!(user: user, title: 'X')
      stub_current_user(user)
      put "/combinations/#{c.id}", params: { combination: { title: 'Edited', tags: ['t'] } }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Edited')
      expect(json['tags']).to eq(['t'])
    end
  end

  describe 'DELETE /combinations/:id' do
    it 'deletes own combination' do
      c = Combination.create!(user: user, title: 'X')
      stub_current_user(user)
      delete "/combinations/#{c.id}"
      expect(response).to have_http_status(:ok)
    end
  end
end
