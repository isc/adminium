REDIS = Redis.new url: Figaro.env.redis_url, db: (1 if Rails.env.test?)

Rails.application.config.middleware.use OmniAuth::Builder do
  client_options = Figaro.env.proxy_url.present? ? { connection_opts: { proxy: Figaro.env.proxy_url } } : {}
  provider :google_oauth2, Figaro.env.google_oauth_client_id, Figaro.env.google_oauth_client_secret,
    scope: ['userinfo.email'], access_type: 'online', client_options: client_options
end

if Figaro.env.use_heroku_omniauth
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :heroku, Figaro.env.heroku_oauth_id, Figaro.env.heroku_oauth_secret,
      scope: 'identity, write-protected', fetch_info: true
  end
end
