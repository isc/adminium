if ENV["REDISTOGO_URL"]
  REDIS = Redis.connect url: ENV["REDISTOGO_URL"]
else
  REDIS = Redis.new db: (Rails.env.test? ? 3 : 0)
end
Rails.application.config.middleware.use OmniAuth::Strategies::OpenID, store: OpenID::Store::Redis.new(REDIS),
  name: 'google', identifier: 'https://www.google.com/accounts/o8/id'
