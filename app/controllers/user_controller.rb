class UserController < ApplicationController
  skip_before_action :authenticate_user, only: [:create]
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
      image: user.image.attached? ? url_for(user.image) : nil
    )
  end

  private

  def user_params
    params.require(:user).permit(:image, :firebase_uid, :name, :introduction)
  end
end
