class HomeController < ApplicationController

  $client = Twitter::REST::Client.new do |config|
    config.consumer_key = Rails.application.secrets.consumer_key
    config.consumer_secret = Rails.application.secrets.consumer_secret
    config.access_token = Rails.application.secrets.access_token
    config.access_token_secret = Rails.application.secrets.access_token_secret
  end

  def get_tweet
    # user = params[:handle]
    tweets = $client.user_timeline("PMOIndia", count: 5)
    tweets.each do |tweet|
      # calssify and store in DB
      if tweet.media? and tweet.media[0].type == 'photo'
        puts "PIC FOUND"
      end
    end
  end

end
