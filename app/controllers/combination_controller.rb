class CombinationController < ApplicationController
  # GET /combinations
  def index
    combinations = Combination.all.with_attached_image
    render json: combinations.map { |c| 
      c.as_json.merge(
        image: c.image.attached? ? url_for(c.image) : nil
      )
    }
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
