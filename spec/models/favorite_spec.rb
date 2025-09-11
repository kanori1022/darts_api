require 'rails_helper'

RSpec.describe Favorite, type: :model do
  it 'validates uniqueness of [user_id, combination_id]' do
    user = User.create!(firebase_uid: 'u3')
    comb = Combination.create!(user: user, title: 'X')
    described_class.create!(user: user, combination: comb)
    dup = described_class.new(user: user, combination: comb)
    dup.validate
    expect(dup.errors[:user_id]).to include('has already been taken')
  end
end


