require 'rails_helper'

RSpec.describe Combination, type: :model do
  describe 'associations and validations' do
    it 'validates presence of title' do
      combination = described_class.new(title: nil)
      combination.validate
      expect(combination.errors[:title]).to include("can't be blank")
    end

    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe '.popular scope' do
    it 'orders by favorites count desc' do
      user = User.create!(firebase_uid: 'u1')
      c1 = described_class.create!(user: user, title: 'A')
      c2 = described_class.create!(user: user, title: 'B')
      Favorite.create!(user: user, combination: c2)
      expect(described_class.popular.first).to eq(c2)
    end
  end

  describe '#tag_names and #tag_names=' do
    it 'sets and gets tag names' do
      user = User.create!(firebase_uid: 'u2')
      c = described_class.create!(user: user, title: 'T')
      c.tag_names = %w[ruby darts]
      expect(c.tags.pluck(:name)).to match_array(%w[ruby darts])
      expect(c.tag_names).to match_array(%w[ruby darts])
    end
  end
end


