class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :combination

  # 同じユーザーが同じコンビネーションを複数回お気に入りにできないようにする
  validates :user_id, uniqueness: { scope: :combination_id }
end
