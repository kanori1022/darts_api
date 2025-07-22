class UserController < ApplicationController
  # AxiosError: Request failed with status code 500

  # POST /users
  def create
    user = User.new(user_params)
    user.id = @current_user.id
    puts "----------------------------------------------"
    puts "user.id: #{user.id}"
    puts "user.name: #{user.name}"
    puts "----------------------------------------------"
    # user.save
    if user.save
      render json: user, status: :created
    else
      render json: user.errors, status: :unprocessable_entity
    end
  end


  private

  # 受け付けるパラメータを指定
  def user_params
    params.require(:user).permit(:image, :name)
  end
end
