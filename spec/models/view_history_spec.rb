require 'rails_helper'

RSpec.describe ViewHistory, type: :model do
  it 'validates presence of user_id and combination_id' do
    vh = described_class.new
    vh.validate
    expect(vh.errors[:user_id]).to include("can't be blank")
    expect(vh.errors[:combination_id]).to include("can't be blank")
  end
end


