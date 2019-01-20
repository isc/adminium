require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'csv'

module Adminium
  class Application < Rails::Application
    config.filter_parameters += %i(password db_url)
    config.active_record.time_zone_aware_types = %i(datetime time)
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0
  end
end
