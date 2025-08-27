class Tagging < ApplicationRecord
  # アソシエーション
  belongs_to :tag
  belongs_to :combination

  # バリデーション
  validates :tag_id, uniqueness: { scope: :combination_id }
end
