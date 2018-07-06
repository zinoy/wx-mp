class WxPageController < ApplicationController

  include WxPageHelper

  def messages
    @msgs = Message.paginate(page: params[:page]).order('id DESC')
  end
  
  def followers
    access_token = get_access_token
    res = HTTParty.get("https://api.weixin.qq.com/cgi-bin/user/get?access_token=#{access_token}&next_openid=")
    data = JSON.parse(res.body)
    puts data
    
    @output = data["data"]["openid"] unless data.has_key? "errcode"
  end

  private
  
  def get_access_token
    redis = Redis.new
    appid = WX['weixin']['appid']
    token = redis.get(appid) if redis.exists appid
    if token.nil?
      res = HTTParty.get("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{appid}&secret=#{WX['weixin']['appsecret']}")
      data = JSON.parse(res.body)

      if data.has_key? 'access_token'
        redis.set(appid, data["access_token"])
        redis.expire(appid, data["expires_in"])

        # _token = Token.new
        # _token.token = data["access_token"]
        # _token.app_id = WX['weixin']['appid']
        # _token.expired = DateTime.now + data["expires_in"].second
        # _token.save
        
        data["access_token"]
      else
        puts "parse error"
      end
    else
      token
    end
  end
end
