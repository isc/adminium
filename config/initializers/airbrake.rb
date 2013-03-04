# Airbrake.configure do |config|
#   config.api_key = '54713a9e51c89e3667a1239fa002b281'
#   config.async = true
# end
Airbrake.configure do |config|
  config.api_key = '1c1382d74eb21147db1207740c108f96'
  config.host    = 'cluscrive-errbit.herokuapp.com'
  config.port    = 443
  config.secure  = config.port == 443
end
