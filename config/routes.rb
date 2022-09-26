Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :users
  post 'auth/login', to: 'authentication#login'
  put 'auth/logout', to: 'authentication#logout'
  get 'auth/ping', to: 'authentication#ping'

  # Defines the root path route ("/")
  # root "articles#index"
end
