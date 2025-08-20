class CombinationController < ApplicationController
skip_before_action :authenticate_user, only: [:index, :show, :newest, :search]

# GET /combinations (人気順)
def index
  limit = (params[:limit] || 10).to_i
  offset = (params[:offset] || 0).to_i

  combinations = Combination.joins("LEFT JOIN favorites ON favorites.combination_id = combinations.id")
                            .group("combinations.id")
                            .order("COUNT(favorites.id) DESC")
                            .with_attached_image

  # 総件数を取得（ページネーション用）- GROUP BY句がある場合は別途取得
  total_count = Combination.count

  # limitとoffsetを適用
  combinations = combinations.limit(limit).offset(offset)

  # 現在のページと総ページ数を計算
  current_page = (offset / limit) + 1
  total_pages = (total_count.to_f / limit).ceil

  render json: {
    combinations: combinations.map { |c|
      c.as_json.merge(
        image: c.image.attached? ? url_for(c.image) : nil
      )
    },
    pagination: {
      current_page: current_page,
      per_page: limit,
      total_count: total_count,
      total_pages: total_pages
    }
  }
end

# GET /combinations/newest
def newest
  limit = (params[:limit] || 10).to_i
  offset = (params[:offset] || 0).to_i

  combinations = Combination.order(created_at: :desc).with_attached_image

  # 総件数を取得（ページネーション用）
  total_count = combinations.count

  # limitとoffsetを適用
  combinations = combinations.limit(limit).offset(offset)

  # 現在のページと総ページ数を計算
  current_page = (offset / limit) + 1
  total_pages = (total_count.to_f / limit).ceil

  render json: {
    combinations: combinations.map { |c|
      c.as_json.merge(
        image: c.image.attached? ? url_for(c.image) : nil
      )
    },
    pagination: {
      current_page: current_page,
      per_page: limit,
      total_count: total_count,
      total_pages: total_pages
    }
  }
end

# GET /combinations/search - 検索機能
def search
  search_word = params[:searchWord] || ""
  tags = params[:tags] || ""
  limit = (params[:limit] || 10).to_i
  offset = (params[:offset] || 0).to_i

  combinations = Combination.all.with_attached_image

  if search_word.present?
    combinations = combinations.where(
      "title LIKE ? OR description LIKE ? OR flight LIKE ? OR shaft LIKE ? OR barrel LIKE ? OR tip LIKE ?",
      "%#{search_word}%", "%#{search_word}%", "%#{search_word}%", "%#{search_word}%", "%#{search_word}%", "%#{search_word}%"
    )
  end

  if tags.present?
    combinations = combinations.where("description LIKE ?", "%#{tags}%")
  end

  # 人気順でソート
  combinations = combinations.joins("LEFT JOIN favorites ON favorites.combination_id = combinations.id")
                            .group("combinations.id")
                            .order("COUNT(favorites.id) DESC")

  # 総件数を取得（ページネーション用）- GROUP BY句がある場合は別途取得
  base_combinations = Combination.all
  if search_word.present?
    base_combinations = base_combinations.where(
      "title LIKE ? OR description LIKE ? OR flight LIKE ? OR shaft LIKE ? OR barrel LIKE ? OR tip LIKE ?",
      "%#{search_word}%", "%#{search_word}%", "%#{search_word}%", "%#{search_word}%", "%#{search_word}%", "%#{search_word}%"
    )
  end
  if tags.present?
    base_combinations = base_combinations.where("description LIKE ?", "%#{tags}%")
  end
  total_count = base_combinations.count

  # limitとoffsetを適用
  combinations = combinations.limit(limit).offset(offset)

  # 現在のページと総ページ数を計算
  current_page = (offset / limit) + 1
  total_pages = (total_count.to_f / limit).ceil

  render json: {
    combinations: combinations.map { |c|
      c.as_json.merge(
        image: c.image.attached? ? url_for(c.image) : nil
      )
    },
    pagination: {
      current_page: current_page,
      per_page: limit,
      total_count: total_count,
      total_pages: total_pages
    }
  }
end

  # AxiosError: Request failed with status code 500

  # POST /combinations
  def create
    combination = Combination.new(combination_params)
    # user_idを "1" に仮置きしている
    combination.user_id = @current_user.id
    puts "----------------------------------------------"
    puts "combination.title: #{combination.title}"
    puts "combination.user_id: #{combination.user_id}"
    puts "----------------------------------------------"
    # combination.save
    if combination.save
      render json: combination, status: :created
    else
      render json: combination.errors, status: :unprocessable_entity
    end
  end

  def show
    combination = Combination.find(params[:id])
    render json: combination.as_json.merge(
      image: combination.image.attached? ? url_for(combination.image) : nil
    )
  end

  private

  # 受け付けるパラメータを指定
  def combination_params
    params.require(:combination).permit(:title, :image, :flight, :shaft, :barrel, :tip, :description)
  end
end
