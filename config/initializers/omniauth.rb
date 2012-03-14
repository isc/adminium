require 'openid/store/filesystem'
Rails.application.config.middleware.use OmniAuth::Strategies::OpenID, :store => OpenID::Store::Filesystem.new('/tmp'),
  :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
