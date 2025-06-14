class CombinationController < ApplicationController
  # GET /combinations
  def index
    # combination = Combination.find(1)
    combination = Combination.all
    render json: combination
  end

  # POST /combinations
  def create
    combination = Combination.new(combination_params)
    # user_idを "1" に仮置きしている
    combination.user_id = 1
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

  private

  # 受け付けるパラメータを指定
  def combination_params
    params.require(:combination).permit(:title, :flight, :shaft, :barrel, :tip, :description)
  end
end
