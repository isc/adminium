WebAuthn.configure do |config|
    config.origin = ENV.fetch("APP_URL", "http://localhost:3000")
    config.rp_name = "Adminium"
    config.credential_options_timeout = 120_000
  end
