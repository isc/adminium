REDIS = Redis.new url: Figaro.env.redis_url, db: (1 if Rails.env.test?),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }

Rails.application.config.middleware.use OmniAuth::Builder do
  client_options = Figaro.env.proxy_url.present? ? { connection_opts: { proxy: Figaro.env.proxy_url } } : {}
  provider :google_oauth2, Figaro.env.google_oauth_client_id, Figaro.env.google_oauth_client_secret,
    scope: ['userinfo.email'], access_type: 'online', client_options: client_options
end
