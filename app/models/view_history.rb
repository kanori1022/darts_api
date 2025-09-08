class ViewHistory < ApplicationRecord
  belongs_to :user
  belongs_to :combination

  validates :user_id, presence: true
  validates :combination_id, presence: true
end
