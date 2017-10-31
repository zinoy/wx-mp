class WxPageController < ApplicationController
  
  def messages
    @msgs = Message.paginate(page: params[:page])
  end
  
end
