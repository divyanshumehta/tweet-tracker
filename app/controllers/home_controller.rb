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
    new_track = {}
    followed_users.each do |user|
      find = User.where(handle:user).first
      if find.nil?
        u=User.new
        u.handle = user
        test_tweet = $twitter_client.user_timeline("#{user}", count: 1)
        u.last_tweet = test_tweet[0].id
        u.save
        client.users<<u
        new_track[user] = u.last_tweet
      else
          client.users<<find
          # Client follows existing user
          if client[user].nil?
            new_track[user] = find.last_tweet
          # Client already follows the handle
          else
            new_track[user] = client.track[user]
          end
      end
    end
    client.track = new_track
    client.save
  end

  def get_tweet
    @data = []
    client = Client.where(token:params[:token]).first
    client.users.each do |user|

      # Query all tweets of the user followed by client
      db_tweets = Tweet.where(user_id:user.id,category: params[:category],ID: { :$gt => client.track[user.handle] })
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
    # Run Updater
    client = Client.where(token:params[:token]).first
    client.users.each do |user|

      # Check if new tweets by user
      test_tweet = $twitter_client.user_timeline("#{user.handle}", count: 1)

      # Add new tweets to DB
      if test_tweet[0].id > user.last_tweet
        puts "New Tweets found for user:" + user.handle
        tweets = $twitter_client.user_timeline("#{user.handle}", since_id: user.last_tweet)
        puts "Count of new tweets for user:" + user.handle + " " + tweets.count.to_s
        user.last_tweet = tweets[0].id
        user.save
        tweets.reverse.each do |tweet|
          # calssify and store new tweets in DB
          t = Tweet.new
          if tweet.media?
            if tweet.media[0].type == 'photo'
              if tweet.full_text.blank?
                t.category = "photo"
                # Update photo_notify for all the clients of this user
                user.clients.each do |c|
                  c.photo_notify = true
                  c.save
                end
              else
                t.category = "text and photo"
                # Update text_and_photo_notify for all the clients of this user
                user.clients.each do |c|
                  c.text_and_photo_notify = true
                  c.save
                end
              end
            else
              #nothing happens
            end
          else
            t.category = "text"
            # Update text_notify for all the clients of this user
            user.clients.each do |c|
              c.text_notify = true
              c.save
            end
          end
          t.user = User.where(handle:user.handle).first
          t.text = tweet.full_text
          t.url = tweet.url.to_s
          t.tweeted_at = tweet.created_at
          t.ID = tweet.id
          puts t.inspect
          t.save!
        end
      end
    end

    # Run Notifier
    data = {}
    client = Client.where(token:params[:token]).first
    data[:text] = false
    data[:photo] = false
    data[:text_and_photo] = false
    if client.text_notify
      client.text_notify = false
      data[:text] = true
    end
    if client.photo_notify
      client.photo_notify = false
      data[:photo] = true
    end
    if client.text_and_photo_notify
      client.text_and_photo_notify = false
      data[:text_and_photo] = true
    end
    client.save
    puts data.inspect
    respond_to do |format|
      format.json { render json: data }
    end
  end

end
