class UserController < ApplicationController
  skip_before_action :authenticate_user, only: [:create, :show_by_id, :user_combinations]
  # POST /users
  def create
    user = User.new(user_params)
    puts "----------------------------------------------"
    puts "user.name: #{user.name}"
    puts "----------------------------------------------"

    if user.save
      render json: user, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # PUT /users
  def update
    user = User.find_by(id: @current_user.id)
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    puts "========== PARAMS =========="
    puts params.inspect
    puts "============================"

    if user.update(user_params)
      render json: user, status: :ok
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end

  # GET /users
  def show
    user = User.find_by(id: @current_user.id)
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end
    render json: user.as_json.merge(
      image: user.image.attached? ? url_for(user.image) : nil,
      headerGradientFrom: user.header_gradient_from,
      headerGradientTo: user.header_gradient_to
    )
  end

  # GET /users/:id
  def show_by_id
    user = User.find_by(id: params[:id])
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end
    render json: user.as_json.merge(
      image: user.image.attached? ? url_for(user.image) : nil,
      headerGradientFrom: user.header_gradient_from,
      headerGradientTo: user.header_gradient_to
    )
  end

  # GET /users/:id/combinations
  def user_combinations
    user = User.find_by(id: params[:id])
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    limit = (params[:limit] || 10).to_i
    offset = (params[:offset] || 0).to_i

    # 指定されたユーザーの投稿のみを取得
    combinations = user.combinations.includes(:user).order(created_at: :desc).with_attached_image

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
          tags: c.tag_names,
          firebase_uid: c.user.firebase_uid
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

  private

  def user_params
    params.require(:user).permit(:image, :firebase_uid, :name, :introduction, :header_gradient_from, :header_gradient_to)
  end
end
