source 'http://rubygems.org'

gem 'rails', '3.2.2'

gem 'pg'
gem "hiredis", "~> 0.3.1"
gem "redis", ">= 2.2.0", :require => ["redis", "redis/connection/hiredis"]
gem 'configatron'
gem 'jquery-rails'
gem 'slim-rails'
gem 'kaminari'
gem 'simple_form'
gem 'omniauth-openid'
gem 'heroku-nav', :require => 'heroku/nav'
gem 'rest-client'
gem 'attr_encrypted', :git => 'git://github.com/hron/attr_encrypted.git', :branch => 'issue-2-ruby19-compatibility'
gem 'airbrake'

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
end

group :production do
  gem 'puma'
end

group :test do
  gem 'turn', '0.8.2', :require => false
  gem 'capybara'
  gem 'launchy'
  gem 'factory_girl_rails'
end
