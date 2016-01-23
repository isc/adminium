REDIS = Redis.new url: Figaro.env.redis_url, db: (Rails.env.test? ? 3 : 0)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Figaro.env.google_oauth_client_id, Figaro.env.google_oauth_client_secret,
    {scope: ['userinfo.email'], access_type: 'online',
     client_options: Figaro.env.external_tools_proxy.present? ? {connection_opts: {proxy: Figaro.env.external_tools_proxy}} : {}
    }
end

if Figaro.env.use_heroku_omniauth
  Rails.application.config.middleware.use OmniAuth::Builder do
    oauth_id = Figaro.env.heroku_oauth_id
    secret = Figaro.env.heroku_oauth_secret
    provider :heroku, oauth_id, secret, scope: 'identity, write-protected'
  end
end
