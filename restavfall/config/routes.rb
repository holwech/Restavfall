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
  post 'auth/facebook/callback', to: 'home#login'
  get 'fb_policy', to: 'home#policy'
  get 'test', to: 'home#test'
  get 'ukeevent', to: 'ukeevent#index'
  get 'ukeeventdata', to: 'ukeevent#event_data'
  post 'ukeeventdata', to: 'ukeevent#save_data'
  #get '*path' => redirect('/')
  #post '*path' => redirect('/')
end
