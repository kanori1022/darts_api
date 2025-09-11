require 'rails_helper'

RSpec.describe "Favorites API", type: :request do
  let!(:user) { User.create!(firebase_uid: 'uidf1') }
  let!(:other) { User.create!(firebase_uid: 'uidf2') }
  let!(:others_comb) { Combination.create!(user: other, title: 'O') }

  describe 'GET /favorites' do
    it 'returns ids favorited by current user' do
      Favorite.create!(user: user, combination: others_comb)
      stub_current_user(user)
      get '/favorites'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['favorite_combination_ids']).to include(others_comb.id)
    end
  end

  describe 'POST /favorites' do
    it 'adds favorite for others combination' do
      stub_current_user(user)
      post '/favorites', params: { combination_id: others_comb.id }
      expect(response).to have_http_status(:created)
    end

    it 'forbids favoriting own combination' do
      my_comb = Combination.create!(user: user, title: 'M')
      stub_current_user(user)
      post '/favorites', params: { combination_id: my_comb.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /favorites/:combination_id' do
    it 'removes favorite' do
      Favorite.create!(user: user, combination: others_comb)
      stub_current_user(user)
      delete "/favorites/#{others_comb.id}"
      expect(response).to have_http_status(:ok)
    end
  end
end


