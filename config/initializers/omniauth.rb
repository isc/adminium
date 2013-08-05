if ENV["REDISTOGO_URL"]
  REDIS = Redis.connect url: ENV["REDISTOGO_URL"]
else
  REDIS = Redis.new db: (Rails.env.test? ? 3 : 0)
end
Rails.application.config.middleware.use OmniAuth::Strategies::OpenID, store: OpenID::Store::Redis.new(REDIS),
  name: 'google', identifier: 'https://www.google.com/accounts/o8/id'

Rails.application.config.middleware.use OmniAuth::Builder do
  oauth_id = ENV['HEROKU_OAUTH_ID'] || "e7f8380e-7f68-4ce4-acd0-776e7408a304"
  secret = ENV['HEROKU_OAUTH_SECRET'] || "9e9cb609-34c9-4e66-9006-8be043faa681"
  provider :heroku, oauth_id, secret, scope: 'identity, write-protected'
end