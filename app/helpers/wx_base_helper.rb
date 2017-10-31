module WxBaseHelper
  
  private
  
  BLOCK_SIZE = 32
  
  def aes256_encrypt(text)
    aeskey = WX['weixin']['aeskey']

    aes = OpenSSL::Cipher.new('AES-256-CBC')
    aes.encrypt
    aes.padding = 0
    aes.key = Base64.decode64("#{aeskey}=")
    aes.iv = aeskey[0...16]
    
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
  
  def aes256_decrypt(text)
    aeskey = WX['weixin']['aeskey']

    aes = OpenSSL::Cipher.new('AES-256-CBC')
    aes.decrypt
    aes.padding = 0
    aes.key = Base64.decode64("#{aeskey}=")
    aes.iv = aeskey[0...16]
    content = aes.update(Base64.decode64 text) + aes.final

    pad = content[-1].ord
    pad = 0 if (pad < 1 || pad > BLOCK_SIZE)
    size = content.size - pad
    content[0...size]
  end

end
