# -*- coding: utf-8 -*-
require 'oauth'
require 'rubytter'
require 'json'
require 'time'
require 'pp'

require 'bugcloudbot/auth'
require 'bugcloudbot/tokens'

module BugcloudBot
  class Main
    TWEET_SOURCE   = 'data/source.txt'
    SETTING_FILE   = 'data/setting.txt'

    # コンストラクタ
    def initialize
      $KCODE = 'utf8'

      # rubytterの準備
      @rubytter = BugcloudBot::Auth.get_oauth_rubytter

      # APIの利用残を取得
#       rate_limit_status = @rubytter.limit_status
#       puts rate_limit_status
#       exit

      # source.txtの読み込み
      eval(File.open(TWEET_SOURCE).read)

      # セッティングの読み込み
      if File.exists? SETTING_FILE
        eval(File.open(SETTING_FILE).read)
      else
        # default :since_id is '5384414604' => http://twitter.com/bugcloud/status/5384414604
        @since_id = 5384414604
      end

      # メイン処理
      main

    end

    def main
      # friends_timelineを取得
      last_time_line = get_last_friends_timeline

      last_since_id = last_time_line[last_time_line.length-1][:id]
      # 取得したstatus_idの最大値を保存
      save_settings last_since_id

      #debug
      #pp last_since_id

      @tweet_source.each do |t_s|
      temp = []
      # 取得したtimelineの中からsource.txtに設定した内容にマッチするものを抽出
        last_time_line.each do |t|
          if /#{t_s[0]}/ =~ t[:text]
            if /#{t_s[1]}/ =~ t[:text]
              if /#{t_s[2]}/ =~ t[:text]
                temp<<t
              end
            end
          end
        end

        if temp.length > 0
          # 存在するならreply
          temp.each do |t|

            # debug
            #pp t[:text]

            #if t[:user][:screen_name] == 'kyubot'
            if t[:user][:screen_name] == 'kyubot'
              # for "kyubot" http://twitter.com/kyubot
              tweeter = t[:text].scan(/@[a-zA-Z0-9_]+/)
              reply_tweet = tweeter[0]
              reply_tweet += t_s[3] + ' ' + t_s[4]
              # debug
              #pp reply_tweet

              update reply_tweet
            else
              reply_tweet = '@' + t[:user][:screen_name]
              reply_tweet += t_s[3] + ' ' + t_s[4]
              # debug
              #pp reply_tweet

              update reply_tweet
            end
          end
        end
      end
    end

    # 設定を保存
    def save_settings since_id
      File.open(SETTING_FILE, 'w') { |w|
        w.puts "@since_id = #{since_id}"
      }
    end

    # timelineを取得
    def get_last_friends_timeline
        @rubytter.friends_timeline(:count => 200, :since_id => @since_id)
    end

    #update
    def update text
      begin
        @rubytter.update text
        p 'success'
      rescue Rubytter::APIError
        p 'APIError occured!'
      end
    end

  end

  # エントリポイント
  bot = Main.new
end
