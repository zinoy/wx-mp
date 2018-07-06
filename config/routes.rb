Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'miscellaneous#blank_page'

  # AJAX
  get 'ajax/email_compose', to: 'ajax#email_compose', as: :ajax_email_compose
  get 'ajax/email_list', to: 'ajax#email_list', as: :ajax_email_list
  get 'ajax/email_opened', to: 'ajax#email_opened', as: :ajax_email_opened
  get 'ajax/email_reply', to: 'ajax#email_reply', as: :ajax_email_reply
  get 'ajax/demo_widget', to: 'ajax#demo_widget', as: :ajax_demo_widget
  get 'ajax/data_list.json', to: 'ajax#data_list', as: :ajax_data_list
  get 'ajax/notify_mail', to: 'ajax#notify_mail', as: :ajax_notify_mail
  get 'ajax/notify_notifications',
      to: 'ajax#notify_notifications',
      as: :ajax_notify_notifications
  get 'ajax/notify_tasks', to: 'ajax#notify_tasks', as: :ajax_notify_tasks

  # Misc methods
  get '/home/set_locale', to: 'home#set_locale', as: :home_set_locale

  # CK editor
  mount Ckeditor::Engine => '/ckeditor'
  
  # WX base
  get 'wx/messages', to: 'wx_base#verify_token'
  post 'wx/messages', to: 'wx_base#messages'
  
  # WX page
  get 'messages', to: 'wx_page#messages'
  get 'followers', to: 'wx_page#followers'
  
  # SN Generator
  get 'sn', to: 'series_number#list'
  get 'sn/new', to: 'series_number#new'
  post 'sn/new', to: 'series_number#new'
  get 'sn/dl/:key', to: 'series_number#download', as: :sn_dl

end
