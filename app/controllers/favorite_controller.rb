class FavoriteController < ApplicationController
  # GET /favorites - ユーザーのお気に入り一覧を取得
  def index
    favorites = @current_user.favorites.includes(:combination)
    combination_ids = favorites.map(&:combination_id)

    render json: { favorite_combination_ids: combination_ids }
  end

  # POST /favorites - お気に入りに追加
  def create
    combination_id = params[:combination_id] || params.dig(:favorite, :combination_id)
    combination = Combination.find(combination_id)

    # 自分の投稿をお気に入りに追加しようとしている場合はエラー
    if combination.user_id == @current_user.id
      render json: { error: "自分の投稿をお気に入りに追加することはできません" }, status: :forbidden
      return
    end

    # 既に追加済みかチェック
    existing_favorite = @current_user.favorites.find_by(combination: combination)
    if existing_favorite
      render json: { message: "既にお気に入りに追加済みです", favorite_id: existing_favorite.id }, status: :ok
      return
    end

    favorite = @current_user.favorites.build(combination: combination)

    if favorite.save
      render json: { message: "お気に入りに追加しました", favorite_id: favorite.id }, status: :created
    else
      render json: { error: favorite.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "コンビネーションが見つかりません" }, status: :not_found
  end

  # DELETE /favorites/:combination_id - お気に入りから削除
  def destroy
    combination = Combination.find(params[:combination_id])
    favorite = @current_user.favorites.find_by(combination: combination)

    if favorite
      favorite.destroy
      render json: { message: "お気に入りから削除しました" }
    else
      render json: { error: "お気に入りが見つかりません" }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "コンビネーションが見つかりません" }, status: :not_found
  end

  private

  def favorite_params
    params.require(:favorite).permit(:combination_id)
  end
end
