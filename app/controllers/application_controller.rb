class ApplicationController < ActionController::API
  before_action :authenticate_user

  private

  # ユーザー認証
  def authenticate_user
    # リクエストヘッダーからJWTトークンを取得
    token = request.headers["Authorization"]&.sub(/^Bearer /, "") # JWTトークンのペイロードを検証

    # tokenが存在しているかどうか確認する(空のことがあるので)
    if token.present?
      payload, header = JWT.decode(token, nil, false)
      if payload["iss"] == "https://securetoken.google.com/combines-darts"
        # ユーザーIDからユーザーを取得
        user = User.find_by(firebase_uid: payload["user_id"])
        # ユーザーが存在しているかどうか確認する
        if user.present?
          # ユーザーが存在していれば@current_userに代入する
          @current_user = user
        end
      end
    end

    # 認証失敗
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end
end
