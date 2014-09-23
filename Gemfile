source 'http://rubygems.org'

ruby '2.0.0'

gem 'rails', '4.0.10'
gem 'pg'
gem 'sendgrid'
gem 'premailer-rails'
gem 'sequel', '4.4.0'
gem 'sequel_pg', '1.6.8', require: 'sequel'
gem 'hiredis', '0.4.5'
gem 'redis', '3.0.4', require: ["redis", "redis/connection/hiredis"]
gem 'configatron', '2.10.0'
gem 'jquery-rails', '2.0.1'
gem 'slim-rails'
gem 'kaminari'
gem 'json', "1.8.1"
gem 'simple_form', '3.0.2'
gem 'omniauth-openid'
gem 'omniauth-heroku'
gem 'heroku-api', '0.3.15'
gem 'excon'
gem 'openid-store-redis'
gem 'rest-client'
gem 'country_select'
gem 'attr_encryptor'
gem 'airbrake'
gem 'bootstrap-components-helpers'
gem 'bootstrap-wysihtml5-rails', require: 'bootstrap-wysihtml5-rails',
  git: 'git://github.com/Nerian/bootstrap-wysihtml5-rails.git'
gem 'newrelic_rpm'
gem 'select2-rails'
gem 'binary_search', require: 'binary_search/pure'
gem 'protected_attributes'
gem 'coffee-rails'
gem 'uglifier', '>= 1.3.0'
gem 'twitter-bootstrap-rails', '2.0.4'
gem 'figaro'

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
  gem 'pry-rails'
  gem 'xray-rails'
  gem 'guard', require: false
  gem 'rb-fsevent', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'guard-livereload', require: false
  gem 'rack-livereload'
  gem 'capistrano'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano3-puma', github: 'seuros/capistrano-puma', require: false
  gem 'capistrano-rbenv', require: false
end

group :production do
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
