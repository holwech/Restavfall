Rails.application.routes.draw do
  resources :events

  root to: 'users#index', via: [:get, :post]
  get 'auth/facebook', as: "auth_provider"
  get 'auth/facebook/callback', to: 'users#login'
  resources :events
end
