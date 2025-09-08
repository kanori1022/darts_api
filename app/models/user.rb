class User < ApplicationRecord
  has_one_attached :image

  # お気に入りとの関連付け
  has_many :favorites, dependent: :destroy
  has_many :favorite_combinations, through: :favorites, source: :combination

  # 投稿したコンビネーションとの関連付け
  has_many :combinations, dependent: :destroy
  has_many :view_histories, dependent: :destroy
end
