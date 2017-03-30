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
    # openid = params[:openid]

    # logger.debug request.raw_post
    
    xml_doc  = Nokogiri::XML(request.raw_post)
    encrypt_type = params[:encrypt_type]
    
    if encrypt_type == "aes"
      encrypt_content = xml_doc.xpath("//Encrypt").first.content
      aeskey = Base64.decode64(WX['weixin']['aeskey'] + "=")
      appid = WX['weixin']['appid']
      content = aes256_decrypt(aeskey, encrypt_content)
      # content = content.encode Encoding::UTF_8, :invalid => :replace, :undef => :replace, :replace => '?'
      # content_pack = content.bytes.pack "C*"
      # puts content_pack
      # content_utf8 = (content_pack.unpack "U*").pack "U*"
      # puts content_utf8.encoding
      # puts content.end_with? appid
      puts content
      
      if content.end_with? appid
        content = content.from 16
        len = content.bytes[0...4].pack("C*").unpack("N")[0]
        xml_doc  = Nokogiri::XML(content.from(4)[0...len])
      else
        render plain: "Unauthorized: bad appid", status: 401
        return
      end
    end

    oId = xml_doc.xpath("//MsgId").first.content
    @message = Message.find_by :origin_id => oId
    msg_type = xml_doc.xpath("//MsgType").first.content

    if @message.nil? && msg_type == "text"
      @message = Message.new
      @message.origin = "wx"
      @message.origin_id = oId
      @message.from = xml_doc.xpath("//FromUserName").first.content
      @message.content = xml_doc.xpath("//Content").first.content
      @message.to = xml_doc.xpath("//ToUserName").first.content
      @message.msg_type = msg_type
      @message.user_id = params[:openid]
      @message.send_at = Time.at(xml_doc.xpath("//CreateTime").first.content.to_i)
      @message.params = request.query_parameters
      @message.save
    end

    if authenticate encrypt_content
      
      if msg_type == "text"
        timestamp = Time.now.to_i.to_s
  
        @doc = Nokogiri::XML::DocumentFragment.parse "<xml></xml>"
        
        root = @doc.at_css 'xml'
        root.add_child '<ToUserName><![CDATA[' + @message.from + ']]></ToUserName>'
        root.add_child '<FromUserName><![CDATA[' + @message.to + ']]></FromUserName>'
        root.add_child '<CreateTime>' + timestamp + '</CreateTime>'
        root.add_child '<MsgType><![CDATA[' + msg_type + ']]></MsgType>'
        root.add_child '<Content><![CDATA[你好 ' + @message.content + ']]></Content>'
    
        if encrypt_type == "aes"
          output = aes256_encrypt aeskey, @doc.to_xml
          testing = aes256_decrypt(aeskey, output)
          padding = testing.bytes[-1] + 1
          testing = testing[0..-padding]
          
          arr = {
            :token => WX['weixin']['token'],
            :timestamp => timestamp,
            :nonce => params[:nonce],
            :msg => output
          }
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
        
        puts output
        render xml: output
      else
        render plain: "success"
      end
    end
  end
  
  private
  
  def get_signature(hash)
    arr = Hash[ hash.sort_by { |key, value| value || "" } ]
    str = arr.values.join
    Digest::SHA1.hexdigest str
  end
  
  def authenticate(content=nil)
    arr = {
      :token => WX['weixin']['token'],
      :timestamp => params[:timestamp],
      :nonce => params[:nonce]
    }
    
    if content.nil?
      signature = params[:signature]
    else
      signature = params[:msg_signature]
      arr[:msg] = content
    end
    sha1 = get_signature arr
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
