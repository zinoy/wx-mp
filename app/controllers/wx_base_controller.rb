class WxBaseController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  
  BLOCK_SIZE = 32

  layout false

  def verify_token
    echostr = params[:echostr]

    if authenticate
      render plain: echostr
    else
      render plain: "Unauthorized: bad signature", status: 401
    end
  end

  def messages
    # logger.debug request.raw_post
    xml_doc  = Nokogiri::XML(request.raw_post)

    puts xml_doc
    encrypt_content = xml_doc.xpath("//Encrypt").first.content unless xml_doc.xpath("//Encrypt").first.nil?
    
    if authenticate encrypt_content

      encrypt_type = params[:encrypt_type]
      if encrypt_type == "aes"
        aeskey = Base64.decode64(WX['weixin']['aeskey'] + "=")
        appid = WX['weixin']['appid']
        content = aes256_decrypt(aeskey, encrypt_content)
        
        if content.end_with? appid
          content = content.from 16
          len = content.bytes[0...4].pack("C*").unpack("N")[0]
          xml_doc  = Nokogiri::XML(content[4...len])
        else
          render plain: "Unauthorized: bad appid", status: 401
          return
        end
      end
      
      msg_type = xml_doc.xpath("//MsgType").first.content
      from = xml_doc.xpath("//FromUserName").first.content
      create_time = Time.at(xml_doc.xpath("//CreateTime").first.content.to_i)
      if msg_type == "event"
        @message = Message.find_by from: from, send_at: create_time
      else
        oId = xml_doc.xpath("//MsgId").first.content unless xml_doc.xpath("//MsgId").first.nil?
        @message = Message.find_by origin_id: oId
      end
  
      if @message.nil?
        @message = Message.new
        @message.origin = "weixin"
        @message.origin_id = oId
        @message.from = from
        @message.content = xml_doc.xpath("//Content").first.content if msg_type == "text"
        @message.to = xml_doc.xpath("//ToUserName").first.content
        @message.msg_type = msg_type
        @message.user_id = from
        @message.media_id = xml_doc.xpath("//MediaId").first.content unless xml_doc.xpath("//MediaId").first.nil?
        @message.send_at = create_time
        @message.params = request.query_parameters
        
        case msg_type
        when "image"
          @message.url = xml_doc.xpath("//PicUrl").first.content
        when "voice"
          @message.format = xml_doc.xpath("//Format").first.content
          @message.content = xml_doc.xpath("//Recognition").first.content unless xml_doc.xpath("//Recognition").first.nil?
        when "video", "shortvideo"
          @message.thumb_media_id = xml_doc.xpath("//ThumbMediaId").first.content
        when "location"
          @message.latitude = xml_doc.xpath("//Location_X").first.content
          @message.longtitude = xml_doc.xpath("//Location_Y").first.content
          @message.scale = xml_doc.xpath("//Scale").first.content
          @message.content = xml_doc.xpath("//Label").first.content
        when "link"
          @message.title = xml_doc.xpath("//Title").first.content
          @message.content = xml_doc.xpath("//Description").first.content
          @message.url = xml_doc.xpath("//Url").first.content
        when "event"
          @message.title = xml_doc.xpath("//Event").first.content
          @message.content = xml_doc.xpath("//EventKey").first.content unless xml_doc.xpath("//EventKey").first.nil?
          @message.origin_id = xml_doc.xpath("//Ticket").first.content unless xml_doc.xpath("//Ticket").first.nil?
          @message.latitude = xml_doc.xpath("//Latitude").first.content unless xml_doc.xpath("//Latitude").first.nil?
          @message.longtitude = xml_doc.xpath("//Longitude").first.content unless xml_doc.xpath("//Longitude").first.nil?
          @message.scale = xml_doc.xpath("//Precision").first.content unless xml_doc.xpath("//Precision").first.nil?
        end
        
        @message.save
        
        if (msg_type != "event" && !@message.content.nil? && !@message.content.empty?) || (msg_type == "event" && @message.title == "subscribe")
          timestamp = Time.now.to_i.to_s
          reply = '[太阳] ' + @message.content
          reply = "欢迎关注皓子窝！这里会提供各种好玩的东东，敬请期待[太阳]" if (msg_type == "event" && @message.title == "subscribe")
          
          @doc = Nokogiri::XML::DocumentFragment.parse "<xml></xml>"
          
          root = @doc.at_css 'xml'
          root.add_child '<ToUserName><![CDATA[' + @message.from + ']]></ToUserName>'
          root.add_child '<FromUserName><![CDATA[' + @message.to + ']]></FromUserName>'
          root.add_child '<CreateTime>' + timestamp + '</CreateTime>'
          root.add_child '<MsgType><![CDATA[text]]></MsgType>'
          root.add_child '<Content><![CDATA[' + reply + ']]></Content>'
          
          if encrypt_type == "aes"
            output = aes256_encrypt aeskey, @doc.to_xml
            
            arr = [WX['weixin']['token'], timestamp, params[:nonce], output]
            sha1 = get_signature arr
            
            @encrypt_doc = Nokogiri::XML::DocumentFragment.parse "<xml></xml>"
            
            root = @encrypt_doc.at_css 'xml'
            root.add_child '<Encrypt><![CDATA[' + output + ']]></Encrypt>'
            root.add_child '<MsgSignature><![CDATA[' + sha1 + ']]></MsgSignature>'
            root.add_child '<TimeStamp>' + timestamp + '</TimeStamp>'
            root.add_child '<Nonce><![CDATA[' + params[:nonce] + ']]></Nonce>'
            
            output = @encrypt_doc.to_xml
          else
            output = @doc.to_xml
          end
          
          render xml: output
        else
          render plain: "success"
        end
      else
        render plain: ""
      end
    else
      render plain: "Unauthorized: bad signature", status: 401
    end
  end
  
  private
  
  def get_signature(arr)
    return "" if arr.include? nil
    str = arr.sort.join
    Digest::SHA1.hexdigest str
  end
  
  def authenticate(content=nil)
    arr = [WX['weixin']['token'], params[:timestamp], params[:nonce]]
    
    if content.nil?
      signature = params[:signature]
    else
      signature = params[:msg_signature]
      arr.push content
    end
    sha1 = get_signature arr
    puts sha1
    signature == sha1
  end
  
  def aes256_encrypt(key, text)
    aes = OpenSSL::Cipher.new('AES-256-CBC')
    aes.encrypt
    aes.padding = 0
    aes.key = key
    aes.iv = key[0...16]
    
    text_8bit = text.force_encoding("ASCII-8BIT")
    random = SecureRandom.random_bytes(16)
    msg_len = [text_8bit.length].pack("N")
    app_id = WX['weixin']['appid']
    buf = "#{random}#{msg_len}#{text_8bit}#{app_id}"

    span = BLOCK_SIZE - buf.length % BLOCK_SIZE
    span = BLOCK_SIZE if span == 0
    pad_chr = span.chr
    buf = "#{buf}#{pad_chr * span}"
    Base64.encode64 aes.update(buf) + aes.final
  end
  
  def aes256_decrypt(key, text)
    aes = OpenSSL::Cipher.new('AES-256-CBC')
    aes.decrypt
    aes.padding = 0
    aes.key = key
    aes.iv = key[0...16]
    content = aes.update(Base64.decode64 text) + aes.final

    pad = content[-1].ord
    pad = 0 if (pad < 1 || pad > BLOCK_SIZE)
    size = content.size - pad
    content[0...size]
  end

end
