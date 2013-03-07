source 'http://rubygems.org'

ruby '1.9.3'

gem 'rails', '3.2.11'

gem 'pg'
gem 'mysql2'
gem "activerecord-import", ">= 0.2.0"
gem "hiredis", "~> 0.3.1"
gem "redis", ">= 2.2.0", require: ["redis", "redis/connection/hiredis"]
gem 'configatron'
gem 'jquery-rails', '2.0.1'
gem 'slim-rails'
gem 'kaminari'
gem 'simple_form', '2.0.4'
gem 'omniauth-openid'
gem 'rest-client'
gem 'country_select'
gem 'attr_encrypted', git: 'git://github.com/hron/attr_encrypted.git', branch: 'issue-2-ruby19-compatibility'
gem 'airbrake', '3.1.8'
gem 'bootstrap-components-helpers', git: 'git://gist.github.com/2117187.git'
gem 'composite_primary_keys', '5.0.10'
gem 'bootstrap-wysihtml5-rails', require: 'bootstrap-wysihtml5-rails',
  git: 'git://github.com/Nerian/bootstrap-wysihtml5-rails.git'

gem 'newrelic_rpm'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'twitter-bootstrap-rails', '~> 2.0.4'
end

group :development do
  gem 'kensa'
  gem 'heroku'
  gem 'taps'
  gem 'populator'
  gem 'faker'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :production do
  gem 'puma'
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'mocha', require: false
  gem 'factory_girl_rails'
  gem 'rack_session_access'
end
