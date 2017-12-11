Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/get_tweets' => 'home#get_tweet'
  get '/notify' => 'home#notifier'
  post '/follow' => 'home#follow_user'
  post '/new_client' => 'home#new_client'
end
