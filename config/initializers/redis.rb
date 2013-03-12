if ENV["REDISTOGO_URL"]
  REDIS = Redis.connect url: ENV["REDISTOGO_URL"]
else
  REDIS = Redis.new db: (Rails.env.test? ? 3 : 0)
end
