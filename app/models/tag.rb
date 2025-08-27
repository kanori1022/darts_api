class Tag < ApplicationRecord
  # アソシエーション
  has_many :taggings, dependent: :destroy
  has_many :combinations, through: :taggings

  # バリデーション
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }

  # スコープ
  scope :popular, -> { joins(:taggings).group("tags.id").order("COUNT(taggings.id) DESC") }

  # クラスメソッド
  def self.find_or_create_by_names(tag_names)
    return [] if tag_names.blank?

    # ActionController::Parametersの場合は配列に変換
    if tag_names.is_a?(ActionController::Parameters)
      tag_names = tag_names.values
    end

    # 文字列の場合は配列に変換
    tag_names = [tag_names] unless tag_names.is_a?(Array)

    tag_names.map do |name|
      find_or_create_by(name: name.strip) if name.present?
    end.compact
  end
end
