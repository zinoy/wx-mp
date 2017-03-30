# :nodoc:
class ApplicationController < ActionController::Base
  before_action :set_gettext_locale
  before_action :authenticate_user!
  protect_from_forgery with: :exception
end
