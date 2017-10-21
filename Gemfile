source 'http://rubygems.org'

ruby '2.3.0'

gem 'airbrake'
gem 'attr_encrypted'
gem 'binary_search', require: 'binary_search/pure'
gem 'bootstrap-components-helpers'
gem 'bootstrap-wysihtml5-rails'
gem 'figaro'
gem 'font-awesome-rails'
gem 'hiredis'
gem 'jquery-rails'
gem 'json'
gem 'newrelic_rpm'
gem 'nokogiri'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-heroku'
gem 'pg'
gem 'platform-api'
gem 'premailer-rails'
gem 'rails', '5.0.6'
gem 'redis', require: ['redis', 'redis/connection/hiredis']
gem 'rest-client'
gem 'sass-rails'
gem 'select2-rails'
gem 'sendgrid'
gem 'sequel'
gem 'sequel_pg', require: 'sequel'
gem 'simple_form'
gem 'slim-rails'

source 'https://rails-assets.org' do
  gem 'rails-assets-bootstrap-datepicker'
end

group :mysql_support do
  gem 'mysql2'
end
group :assets do
  gem 'coffee-rails'
  gem 'uglifier'
end
group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'guard', require: false
  gem 'guard-livereload', require: false
  gem 'kensa'
  gem 'populator'
  gem 'rack-livereload'
  gem 'rack-mini-profiler'
  gem 'rb-fsevent', require: false
  gem 'spring'
  gem 'xray-rails'
end
group :production do
  gem 'puma'
  gem 'puma_worker_killer'
  gem 'rack-timeout'
  gem 'unicorn'
  gem 'unicorn-worker-killer'
end
group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'launchy'
  gem 'minitest'
  gem 'mocha', require: false
  gem 'rack_session_access'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
  gem 'timecop'
end
group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop'
end
