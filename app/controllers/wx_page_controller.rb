class WxPageController < ApplicationController
  
  def messages
    @msgs = Message.paginate(page: params[:page], per_page: 10)
  end
  
end
