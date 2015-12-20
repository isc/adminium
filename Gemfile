source 'http://rubygems.org'

ruby '2.2.4'

gem 'rails', '4.0.13'
gem 'pg'
gem 'sendgrid'
gem 'nokogiri'
gem 'premailer-rails'
gem 'sequel', '4.4.0'
gem 'sequel_pg', '1.6.8', require: 'sequel'
gem 'hiredis'
gem 'redis', require: ["redis", "redis/connection/hiredis"]
gem 'jquery-rails', '2.0.1'
gem 'slim-rails'
gem 'kaminari'
gem 'json'
gem 'simple_form'
gem 'omniauth', '~> 1.2.2'
gem 'omniauth-google-oauth2'
gem 'omniauth-heroku'
gem 'heroku-api', '0.3.15'
gem 'openid-store-redis'
gem 'rest-client'
gem 'country_select'
gem 'attr_encryptor'
gem 'airbrake'
gem 'bootstrap-components-helpers'
gem 'bootstrap-wysihtml5-rails'
gem 'newrelic_rpm'
gem 'select2-rails'
gem 'binary_search', require: 'binary_search/pure'
gem 'protected_attributes'
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier', '>= 1.3.0'
gem 'figaro'
gem 'font-awesome-rails'

source 'https://rails-assets.org' do
  gem 'rails-assets-bootstrap-datepicker'
end

group :mysql_support do
  gem 'mysql2'
end

group :development do
  gem 'kensa'
  gem 'populator'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
  gem 'rack-webconsole-pry', require: 'rack-webconsole'
  gem 'xray-rails'
  gem 'guard', require: false
  gem 'rb-fsevent', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'spring'
end

group :production do
  gem 'rack-timeout'
  gem 'unicorn'
  gem 'unicorn-worker-killer'
  gem 'rails_12factor'
  gem 'puma'
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'timecop'
  gem 'mocha', require: false
  gem 'factory_girl_rails'
  gem 'rack_session_access'
  gem 'simplecov', require: false
  gem 'fakeweb'
end

group :development, :test do
  gem 'pry-rails'
end