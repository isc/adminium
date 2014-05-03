# Airbrake.configure do |config|
#   config.api_key = '54713a9e51c89e3667a1239fa002b281'
#   config.async = true
# end
Airbrake.configure do |config|
  config.api_key = 'bc398701ffc00d54f56509480415a34b'
  config.host    = 'errbit-cluscrive.herokuapp.com'
  config.port    = 443
  config.secure  = config.port == 443
end
