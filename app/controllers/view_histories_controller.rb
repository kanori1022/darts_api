class ViewHistoriesController < ApplicationController
  # 履歴取得: GET /view_histories?limit=&offset=
  def index
    limit = (params[:limit] || 12).to_i
    offset = (params[:offset] || 0).to_i

    histories = ViewHistory.where(user_id: @current_user.id)
                           .order(viewed_at: :desc)
                           .includes(combination: [:user, image_attachment: :blob])
                           .limit(limit)
                           .offset(offset)

    total_count = ViewHistory.where(user_id: @current_user.id).count
    current_page = (offset / limit) + 1
    total_pages = (total_count.to_f / limit).ceil

    render json: {
      histories: histories.map { |h|
        c = h.combination
        {
          id: c.id,
          title: c.title,
          image: c.image.attached? ? url_for(c.image) : nil,
          viewed_at: h.viewed_at
        }
      },
      pagination: {
        current_page: current_page,
        per_page: limit,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end

  # 1件保存: POST /view_histories { combination_id }
  def create
    combination_id = params[:combination_id]
    unless combination_id
      render json: { error: "combination_id is required" }, status: :bad_request
      return
    end

    # 既存を削除して最新で作り直す（latest first）
    ViewHistory.where(user_id: @current_user.id, combination_id: combination_id).delete_all
    history = ViewHistory.new(user_id: @current_user.id, combination_id: combination_id, viewed_at: Time.current)
    if history.save
      # 上限30件を超える古い履歴は削除（新しい順で30件だけ保持）
      ViewHistory.where(user_id: @current_user.id)
                  .order(viewed_at: :desc, id: :desc)
                  .offset(30)
                  .delete_all
      render json: { message: "ok" }, status: :created
    else
      render json: { error: history.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
