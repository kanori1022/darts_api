Rails.application.routes.draw do
  # get "combination/index"
  get "/combinations", to: "combination#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/combinations/:id", to: "combination#show"

  post "/combinations", to: "combination#create"
  post "/users", to: "user#create"
  get "up" => "rails/health#show", as: :rails_health_check

end
