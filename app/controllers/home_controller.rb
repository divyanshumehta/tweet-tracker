class HomeController < ApplicationController

  $twitter_client = Twitter::REST::Client.new do |config|
    config.consumer_key = Rails.application.secrets.consumer_key
    config.consumer_secret = Rails.application.secrets.consumer_secret
    config.access_token = Rails.application.secrets.access_token
    config.access_token_secret = Rails.application.secrets.access_token_secret
  end

  def get_tweet
    data = []
    client = Client.where(token:params[:token]).first
    client.users.each do |user|

      # Check if new tweets by user
      test_tweet = $twitter_client.user_timeline("#{user.handle}", count: 1)

      # Add new tweets to DB
      if test_tweet[0].id > user.last_tweet.to_i
        # get all new tweets only
        puts "New Tweets found for user:" + user.handle
        tweets = $twitter_client.user_timeline("#{user.handle}", since_id: user.last_tweet.to_i)
        puts "Count of new tweets for user:" + user.handle + " " + tweets.count.to_s
        user.last_tweet = tweets[0].id.to_s
        user.save
        tweets.reverse.each do |tweet|
          # calssify and store new tweets in DB
          t = Tweet.new
          if tweet.media?
            if tweet.media[0].type == 'photo'
              if tweet.full_text.blank?
                t.category = "photo"
              else
                t.category = "text and photo"
              end
            else
              t.category = "other media"
            end
          else
            t.category = "text"
          end
          t.user = User.where(handle:user.handle).first
          t.text = tweet.full_text
          t.url = tweet.url.to_s
          t.tweeted_at = tweet.created_at
          puts t.inspect
          t.save!
        end
      end

    puts client
      # Query all tweets of the user followed by client
      db_tweets = Tweet.where(user_id:user.id)
      db_tweets.each do |tweet|
        data << {handle: user.handle, tweet_at: tweet.tweeted_at, url: tweet.url}
      end
    end

    # return all tweets including old ones
    data.sort_by { |hsh| hsh[:tweeted_at] }.reverse

    # Respond with JSON
    # respond_to do |format|
    #   format.json { render json: data }
    # end

  end

end
