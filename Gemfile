source 'http://rubygems.org'

ruby '3.3.0'

gem 'attr_encrypted'
gem 'binary_search', require: 'binary_search/pure'
gem 'bootsnap', require: false
gem 'bootstrap-components-helpers'
gem 'bootstrap-wysihtml5-rails'
gem 'font-awesome-rails'
gem 'httparty'
gem 'jquery-rails'
gem 'json'
gem 'pg'
gem 'rails'
gem 'select2-rails'
gem 'sequel'
gem 'sequel_pg', require: 'sequel'
gem 'simple_form'
gem 'slim-rails'
gem 'sprockets-rails'
gem 'vite_rails'
gem 'webauthn'

group :mysql_support do
  gem 'mysql2'
end
group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'listen'
  gem 'rb-fsevent', require: false
  gem 'spring'
end
group :production do
  gem 'puma'
  gem 'puma_worker_killer'
  gem 'rack-timeout'
end
group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'mocha', require: false
  gem 'rack_session_access'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
  gem 'webdrivers'
end
group :development, :test do
  gem 'pry-rails'
  gem 'rubocop'
  gem 'rubocop-rails_config'
end
