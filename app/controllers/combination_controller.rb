class CombinationController < ApplicationController
skip_before_action :authenticate_user, only: [:index, :show, :newest]

# GET /combinations (人気順)
def index
  combinations = Combination.joins("LEFT JOIN favorites ON favorites.combination_id = combinations.id")
                            .group("combinations.id")
                            .order("COUNT(favorites.id) DESC")
                            .with_attached_image

  render json: combinations.map { |c|
    c.as_json.merge(
      image: c.image.attached? ? url_for(c.image) : nil
    )
  }
end

# GET /combinations/newest
def newest
  combinations = Combination.order(created_at: :desc).with_attached_image

  render json: combinations.map { |c|
    c.as_json.merge(
      image: c.image.attached? ? url_for(c.image) : nil
    )
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
