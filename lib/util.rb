require 'dotenv'
require 'twitter'
require 'user_stream'
require 'color_echo/get'

class Util
  def initialize
    Dotenv.load
    setup_twitter
  end

  def setup_twitter
    UserStream.configure do |config|
      config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
      config.oauth_token = ENV['TWITTER_OAUTH_TOKEN']
      config.oauth_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
      config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
    end
  end

  def exec
    begin
      # UserStream.client.sample({'lang'=>'ja'}) do |status|
      UserStream.client.user do |status|
        analyze status
      end
    rescue => ex
      STDERR.puts ex
      retry
    rescue UserStream::RateLimited => ex
      STDERR.puts 'sleep 300 second...'
      sleep 300
      retry
    rescue Timeout::Error => ex
      STDERR.puts ex.class
      STDERR.puts ex
      if ex.class == UserStream::RateLimited
        STDERR.puts 'sleep 300 second...'
        sleep 300
      end
      retry
    end
  end

  def analyze status
    user = status.user
    text = status.text
    if text and user
      s = text.gsub(/([[:ascii:]]|[[:punct:]])/,'')
      puts s
      if text !~ /^RT / and text !~ /@/ and text !~ /http/ and text =~ /バルス/
        if bals_density_high?(text)
          puts CE.fg(:green).get("@#{user.screen_name}: #{text}")
          @client.update("@#{status.user.screen_name} " + random_message, in_reply_to_status_id: status.id)
          @client.favorite(status.id)
        end
      end
    end
  end

  def random_message
    array = ['ナイスバルス', 'これはいいバルス', 'いいバルスでしたよ〜', 'ラピュタ愛のあふれるバルスでしたね', '素晴らしいバルス']
    array.sample + '!' * rand(1..10)
  end

  def bals_density_high? str
    return false if str.length == 0
    s = str.gsub(/([[:ascii:]]|[[:punct:]])/,'')
    t = s.gsub(/バルス/,'')
    t.length.to_f / s.length.to_f < 0.5
  end
end
