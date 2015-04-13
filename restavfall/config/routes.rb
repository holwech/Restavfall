Rails.application.routes.draw do
  resources :events

  get 'analyse/:stage' => 'home#analyse'
  root to: 'home#index', via: [:get, :post]
  get 'auth/facebook', as: "auth_provider"
  get 'auth/facebook/callback', to: 'home#login'
end
