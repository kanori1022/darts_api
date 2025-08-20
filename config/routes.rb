Rails.application.routes.draw do
  # get "combination/index"
  get "/combinations", to: "combination#index"
  get "/combinations/newest", to: "combination#newest"
  get "/combinations/search", to: "combination#search"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/combinations/:id", to: "combination#show"

  post "/combinations", to: "combination#create"
  post "/users", to: "user#create"

  put "/users", to: "user#update"
  get "/users", to: "user#show"

  # Favorite routes
  get "/favorites", to: "favorite#index"
  post "/favorites", to: "favorite#create"
  delete "/favorites/:combination_id", to: "favorite#destroy"

  get "up" => "rails/health#show", as: :rails_health_check
end
