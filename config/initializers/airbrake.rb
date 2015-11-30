require 'rake'
require 'airbrake/rake_handler'

Airbrake.configure do |config|
  config.api_key = 'de03551fe3ab192c5ba000258d1c2d93'
  config.rescue_rake_exceptions = true
end
