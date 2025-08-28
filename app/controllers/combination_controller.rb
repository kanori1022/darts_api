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
        image: c.image.attached? ? url_for(c.image) : nil,
        tags: c.tag_names
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
        image: c.image.attached? ? url_for(c.image) : nil,
        tags: c.tag_names
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

# GET /combinations/my_posts - 自分の投稿を取得
def my_posts
  limit = (params[:limit] || 10).to_i
  offset = (params[:offset] || 0).to_i

  # 現在のユーザーの投稿のみを取得
  combinations = @current_user.combinations.order(created_at: :desc).with_attached_image

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
        image: c.image.attached? ? url_for(c.image) : nil,
        tags: c.tag_names
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

  # キーワード検索
  if search_word.present?
    combinations = combinations.search_by_keyword(search_word)
  end

  # タグ検索
  if tags.present?
    combinations = combinations.search_by_tags(tags)
  end

  # 人気順でソート
  combinations = combinations.joins("LEFT JOIN favorites ON favorites.combination_id = combinations.id")
                            .group("combinations.id")
                            .order("COUNT(favorites.id) DESC")

  # 総件数を取得（ページネーション用）- GROUP BY句がある場合は別途取得
  base_combinations = Combination.all
  if search_word.present?
    base_combinations = base_combinations.search_by_keyword(search_word)
  end
  if tags.present?
    base_combinations = base_combinations.search_by_tags(tags)
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
        image: c.image.attached? ? url_for(c.image) : nil,
        tags: c.tag_names
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
    combination = Combination.new(combination_params.except(:tags))
    combination.user_id = @current_user.id

    puts "----------------------------------------------"
    puts "combination.title: #{combination.title}"
    puts "combination.user_id: #{combination.user_id}"
    puts "tags: #{params[:combination][:tags]}"
    puts "----------------------------------------------"

    if combination.save
      # タグを設定
      if params[:combination][:tags].present?
        combination.tag_names = params[:combination][:tags]
      end

      render json: combination.as_json.merge(
        image: combination.image.attached? ? url_for(combination.image) : nil,
        tags: combination.tag_names
      ), status: :created
    else
      render json: combination.errors, status: :unprocessable_entity
    end
  end

  def show
    combination = Combination.find(params[:id])
    render json: combination.as_json.merge(
      image: combination.image.attached? ? url_for(combination.image) : nil,
      tags: combination.tag_names
    )
  end

  # PUT /combinations/:id - 投稿を更新
  def update
    combination = Combination.find(params[:id])

    # 自分の投稿かチェック
    if combination.user_id != @current_user.id
      render json: { error: "自分の投稿のみ編集できます" }, status: :forbidden
      return
    end

    if combination.update(combination_params.except(:tags))
      # タグを更新
      if params[:combination][:tags].present?
        combination.tag_names = params[:combination][:tags]
      end

      render json: combination.as_json.merge(
        image: combination.image.attached? ? url_for(combination.image) : nil,
        tags: combination.tag_names
      )
    else
      render json: combination.errors, status: :unprocessable_entity
    end
  end

  # DELETE /combinations/:id - 投稿を削除
  def destroy
    combination = Combination.find(params[:id])

    # 自分の投稿かチェック
    if combination.user_id != @current_user.id
      render json: { error: "自分の投稿のみ削除できます" }, status: :forbidden
      return
    end

    if combination.destroy
      render json: { message: "投稿を削除しました" }, status: :ok
    else
      render json: { error: "削除に失敗しました" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "投稿が見つかりません" }, status: :not_found
  end

  private

  # 受け付けるパラメータを指定
  def combination_params
    params.require(:combination).permit(:title, :image, :flight, :shaft, :barrel, :tip, :description, tags: {})
  end
end
