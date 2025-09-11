require 'rails_helper'

RSpec.describe User, type: :model do
  it 'has associations' do
    expect(described_class.reflect_on_association(:favorites).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:favorite_combinations).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:combinations).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:view_histories).macro).to eq(:has_many)
  end
end


