class Combination < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  # お気に入りとの関連付け（例: Favorite モデルがある場合）
  has_many :favorites, dependent: :destroy

  # バリデーション（必要なら）
  validates :title, presence: true

  # お気に入り数ランキング用のスコープ（動的カウント）
  scope :popular, -> {
    joins("LEFT JOIN favorites ON favorites.combination_id = combinations.id")
    .group("combinations.id")
    .order("COUNT(favorites.id) DESC")
  }
  scope :newest, -> { order(created_at: :desc) }
end
