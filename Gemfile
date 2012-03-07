source 'http://rubygems.org'

gem 'rails', '3.2.2'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'pg'
gem "hiredis", "~> 0.3.1"
gem 'em-redis'
gem "redis"#, "~> 2.2.2", :require => ["redis/connection/synchrony", "redis"]
gem 'em-postgresql-adapter', :git => 'git://github.com/leftbee/em-postgresql-adapter.git'
gem 'rack-fiber_pool',  :require => 'rack/fiber_pool'
gem 'em-synchrony', :git     => 'git://github.com/igrigorik/em-synchrony.git',
                    :require => ['em-synchrony',
                                 'em-synchrony/activerecord']

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'slim-rails'
gem 'kaminari'
gem "twitter-bootstrap-rails", "~> 2.0.1.0"
gem 'simple_form'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

group :development do
  gem 'kensa'
  gem 'heroku'
  gem 'taps'
end

group :production do
  gem 'thin'
end

group :test do
  gem 'turn', '0.8.2', :require => false
  gem 'capybara'
  gem 'launchy'
  gem 'factory_girl_rails'
end

gem 'heroku-nav', :require => 'heroku/nav'
gem 'rest-client'

gem 'attr_encrypted', :git => 'git://github.com/hron/attr_encrypted.git', :branch => 'issue-2-ruby19-compatibility'
