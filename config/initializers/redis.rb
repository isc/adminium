REDIS = Redis.new url: Figaro.env.redis_url, db: (1 if Rails.env.test?),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
