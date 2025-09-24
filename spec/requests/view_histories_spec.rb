require 'rails_helper'

RSpec.describe "ViewHistories API", type: :request do
  let!(:user) { User.create!(firebase_uid: 'uidvh1') }
  let!(:other) { User.create!(firebase_uid: 'uidvh2') }
  let!(:comb) { Combination.create!(user: other, title: 'C') }

  describe 'GET /view_histories' do
    it 'returns paginated histories' do
      # Create histories with distinct combinations to satisfy unique index
      3.times do |i|
        combo = Combination.create!(user: other, title: "C#{i}")
        ViewHistory.create!(user: user, combination: combo, viewed_at: Time.current - i.minutes)
      end
      stub_current_user(user)
      get '/view_histories', params: { limit: 2, offset: 0 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['histories'].length).to eq(2)
      expect(json['pagination']).to include('total_pages')
    end
  end

  describe 'POST /view_histories' do
    it 'creates history and trims to 30 entries' do
      stub_current_user(user)
      # Create 31 unique combinations to avoid unique constraint
      31.times do |i|
        combo = Combination.create!(user: other, title: "T#{i}")
        post '/view_histories', params: { combination_id: combo.id }
        expect(response).to have_http_status(:created)
      end
      expect(ViewHistory.where(user: user).count).to eq(20)
    end

    it 'returns 400 when missing combination_id' do
      stub_current_user(user)
      post '/view_histories'
      expect(response).to have_http_status(:bad_request)
    end
  end
end
