class CombinationController < ApplicationController
  # 一覧
  def index
        conbination = Combination.find(1)
    render json: conbination
  end
end
