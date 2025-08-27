class Combination < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  # お気に入りとの関連付け（例: Favorite モデルがある場合）
  has_many :favorites, dependent: :destroy

  # タグとの関連付け
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  # バリデーション（必要なら）
  validates :title, presence: true

  # お気に入り数ランキング用のスコープ（動的カウント）
  scope :popular, -> {
    joins("LEFT JOIN favorites ON favorites.combination_id = combinations.id")
    .group("combinations.id")
    .order("COUNT(favorites.id) DESC")
  }
  scope :newest, -> { order(created_at: :desc) }

  # タグ関連のスコープ
  scope :with_tags, ->(tag_names) {
    return all if tag_names.blank?
    
    joins(:tags).where(tags: { name: tag_names })
  }

  # タグ関連のメソッド
  def tag_names
    tags.pluck(:name)
  end

  def tag_names=(names)
    return if names.blank?
    
    # 既存のタグ関連付けを削除
    self.tags.clear
    
    # 新しいタグを作成・関連付け
    tag_objects = Tag.find_or_create_by_names(names)
    self.tags = tag_objects
  end

  # 検索用のスコープ
  scope :search_by_keyword, ->(keyword) {
    return all if keyword.blank?
    
    where(
      "title LIKE ? OR description LIKE ? OR flight LIKE ? OR shaft LIKE ? OR barrel LIKE ? OR tip LIKE ?",
      "%#{keyword}%", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%", "%#{keyword}%"
    )
  }

  scope :search_by_tags, ->(tag_names) {
    return all if tag_names.blank?
    
    tag_array = tag_names.is_a?(String) ? [tag_names] : tag_names
    joins(:tags).where(tags: { name: tag_array }).distinct
  }
end
