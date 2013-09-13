source 'http://rubygems.org'

ruby '2.0.0'

gem 'rails', '4.0.0'
gem 'pg'
gem 'mysql2'
gem 'sendgrid'
gem 'premailer-rails'
gem 'sequel', '4.2.0'
gem 'sequel_pg', '1.6.8', require: 'sequel'
gem 'hiredis', '0.4.5'
gem 'redis', '3.0.4', require: ["redis", "redis/connection/hiredis"]
gem 'configatron', '2.10.0'
gem 'jquery-rails', '2.0.1'
gem 'slim-rails'
gem 'kaminari'
gem 'simple_form', '3.0.0.rc'
gem 'omniauth-openid'
gem 'omniauth-heroku'
gem 'heroku-api', '0.3.15'
gem 'excon'
gem 'openid-store-redis'
gem 'rest-client'
gem 'country_select'
gem 'attr_encryptor'
gem 'airbrake', '3.1.8'
gem 'bootstrap-components-helpers'
gem 'bootstrap-wysihtml5-rails', require: 'bootstrap-wysihtml5-rails',
  git: 'git://github.com/Nerian/bootstrap-wysihtml5-rails.git'
gem 'newrelic_rpm', '3.5.8.72'
gem 'select2-rails'
gem 'binary_search', require: 'binary_search/pure'
gem 'protected_attributes'
gem 'coffee-rails'
gem 'uglifier', '>= 1.3.0'
gem 'twitter-bootstrap-rails', '2.0.4'

group :development do
  gem 'kensa'
  gem 'populator'
  gem 'faker'
  gem 'better_errors'
  gem 'binding_of_caller', '0.7.1'
  gem 'quiet_assets'
  gem 'sextant'
  gem 'rack-webconsole-pry', require: 'rack-webconsole'
  gem 'pry-rails'
  gem 'xray-rails'
  gem 'guard', require: false
  gem 'rb-fsevent', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
end

group :production do
  gem 'unicorn'
  gem 'unicorn-worker-killer'
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'timecop'
  gem 'mocha', '0.13.3', require: false
  gem 'factory_girl_rails'
  gem 'rack_session_access'
  gem 'simplecov', require: false
  gem 'fakeweb'
end
