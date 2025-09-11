require 'rails_helper'

RSpec.describe Tagging, type: :model do
  it 'validates uniqueness of [tag_id, combination_id]' do
    user = User.create!(firebase_uid: 'u4')
    comb = Combination.create!(user: user, title: 'Y')
    tag = Tag.create!(name: 'z')
    described_class.create!(tag: tag, combination: comb)
    dup = described_class.new(tag: tag, combination: comb)
    dup.validate
    expect(dup.errors[:tag_id]).to include('has already been taken')
  end
end


