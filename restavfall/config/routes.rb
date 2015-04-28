Rails.application.routes.draw do
  resources :events

  get 'index' => 'home#index'
  get 'analyse/:stage' => 'home#analyse'
  get 'close' => 'home#close'
  get 'uno/:rid(/:redir)' => 'home#uno'
  post 'uno/:rid(/:redir)' => 'home#uno'
  root to: 'home#redirect', via: [:get, :post]
  get 'auth/facebook', as: "auth_provider"
  get 'auth/facebook/callback', to: 'home#login'
end
