REDIS = Redis.new url: Figaro.env.redis_url, db: (Rails.env.test? ? 3 : 4)

Rails.application.config.middleware.use OmniAuth::Builder do
  client_options = Figaro.env.external_tools_proxy.present? ? {connection_opts: {proxy: Figaro.env.external_tools_proxy}} : {}
  provider :google_oauth2, Figaro.env.google_oauth_client_id, Figaro.env.google_oauth_client_secret,
    scope: ['userinfo.email'], access_type: 'online', client_options: client_options
end

if Figaro.env.use_heroku_omniauth
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :heroku, Figaro.env.heroku_oauth_id, Figaro.env.heroku_oauth_secret, scope: 'identity, write-protected'
  end
end
