source 'http://rubygems.org'

ruby '2.3.0'

gem 'rails', '5.0.4'
gem 'pg'
gem 'sendgrid'
gem 'nokogiri'
gem 'premailer-rails'
gem 'sequel'
gem 'sequel_pg', require: 'sequel'
gem 'hiredis'
gem 'redis', require: ['redis', 'redis/connection/hiredis']
gem 'jquery-rails'
gem 'slim-rails'
gem 'kaminari'
gem 'json'
gem 'simple_form'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-heroku'
gem 'platform-api'
gem 'rest-client'
gem 'attr_encryptor'
gem 'airbrake'
gem 'bootstrap-components-helpers'
gem 'bootstrap-wysihtml5-rails'
gem 'newrelic_rpm'
gem 'select2-rails'
gem 'binary_search', require: 'binary_search/pure'
gem 'sass-rails'
gem 'figaro'
gem 'font-awesome-rails'

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
  gem 'kensa'
  gem 'populator'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'xray-rails'
  gem 'guard', require: false
  gem 'rb-fsevent', require: false
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'spring'
  gem 'rack-mini-profiler'
end
group :production do
  gem 'rack-timeout'
  gem 'unicorn'
  gem 'unicorn-worker-killer'
  gem 'rails_12factor'
  gem 'puma'
  gem 'puma_worker_killer'
end
group :test do
  gem 'database_cleaner'
  gem 'capybara'
  gem 'launchy'
  gem 'timecop'
  gem 'mocha', require: false
  gem 'factory_girl_rails'
  gem 'rack_session_access'
  gem 'simplecov', require: false
  gem 'rails-controller-testing'
  gem 'minitest', '~> 5.10', '!= 5.10.2'
end
group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'rubocop'
end
