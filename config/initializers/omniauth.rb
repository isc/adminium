if ENV["REDISTOGO_URL"]
  REDIS = Redis.connect url: ENV["REDISTOGO_URL"]
else
  REDIS = Redis.new db: (Rails.env.test? ? 3 : 0)
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_OAUTH_CLIENT_ID'], ENV['GOOGLE_OAUTH_CLIENT_SECRET'],
    {scope: ['userinfo.email'], access_type: 'online'}
end

Rails.application.config.middleware.use OmniAuth::Builder do
  oauth_id = ENV['HEROKU_OAUTH_ID'] || "e7f8380e-7f68-4ce4-acd0-776e7408a304"
  secret = ENV['HEROKU_OAUTH_SECRET'] || "9e9cb609-34c9-4e66-9006-8be043faa681"
  provider :heroku, oauth_id, secret, scope: 'identity, write-protected'
end
