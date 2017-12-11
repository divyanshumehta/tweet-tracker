class HomeController < ApplicationController
protect_from_forgery :except => [:new_client, :follow_user]

  $twitter_client = Twitter::REST::Client.new do |config|
    config.consumer_key = Rails.application.secrets.consumer_key
    config.consumer_secret = Rails.application.secrets.consumer_secret
    config.access_token = Rails.application.secrets.access_token
    config.access_token_secret = Rails.application.secrets.access_token_secret
  end

  def new_client
    data = {}
    client = Client.where(token:params[:token]).first
    if client.nil?
      client = Client.new
      client.token = params[:token]
      data[:status] = "OK"
      if client.save!
        data[:status] = "OK"
      else
        data[:status] = "SAVE ERROR"
      end
    else
      data[:stauts] = "ERROR"
    end
    respond_to do |format|
      format.json { render json: data }
    end
  end

  def follow_user
    client = Client.where(token:params[:token]).first
    followed_users = params[:users].split(" ")
    client.user_ids = nil
    followed_users.each do |user|
      find = User.where(handle:user).first
      if find.nil?
        u=User.new
        u.handle = user
        test_tweet = $twitter_client.user_timeline("#{user}", count: 1)
        u.last_tweet = test_tweet[0].id.to_s
        u.save
        client.users<<u
      else
          client.users<<find
      end
    end
  end

  def get_tweet
    @data = []
    client = Client.where(token:params[:token]).first
    client.users.each do |user|

      # Query all tweets of the user followed by client
      db_tweets = Tweet.where(user_id:user.id,category: params[:category])
      if db_tweets.count == 0
        puts "No Tweets from user "+user.handle
      else
        db_tweets.each do |tweet|
          @data << {handle: user.handle,text: tweet.text, tweet_at: tweet.tweeted_at, url: tweet.url}
        end
      end
    end

    if @data.count == 0
      render html:"<h1>No Tweets in this category</h1>".html_safe
    else
      # return all tweets including old ones
      @data.sort_by { |hsh| hsh[:tweeted_at] }.reverse
    end
  end

  def notifier
    data = {}
    data[:text] = false;
    data[:photo] = false;
    data[:text_and_photo] = false;
    client = Client.where(token:params[:token]).first
    client.users.each do |user|

      # Check if new tweets by user
      test_tweet = $twitter_client.user_timeline("#{user.handle}", count: 1)

      # Add new tweets to DB
      if test_tweet[0].id > user.last_tweet.to_i
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
                data[:photo] = true
                t.category = "photo"
              else
                data[:text_and_photo] = true
                t.category = "text and photo"
              end
            else
              #nothing happens
            end
          else
            data[:text] = true
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
    end

    # Respond with JSON
      puts data.inspect
    respond_to do |format|
      format.json { render json: data }
    end
  end

end
