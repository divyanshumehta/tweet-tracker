Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/get_tweets' => 'home#get_tweet'
  get '/notify' => 'home#notifier'
  get '/follow' => 'home#follow_user'
end
