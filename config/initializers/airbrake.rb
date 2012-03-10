if false#Rails.env.prod?
  Airbrake.configure do |config|
    config.api_key = '54713a9e51c89e3667a1239fa002b281'
  end
end
