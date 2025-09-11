require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'validates name presence and uniqueness' do
    t1 = described_class.create!(name: 'alpha')
    t2 = described_class.new(name: 'alpha')
    t2.validate
    expect(t2.errors[:name]).to include('has already been taken')
  end

  describe '.find_or_create_by_names' do
    it 'returns array of tags by names' do
      tags = described_class.find_or_create_by_names(%w[a b])
      expect(tags.map(&:name)).to match_array(%w[a b])
    end
  end
end


