TEST_ADAPTER = ENV['adapter'] || ENV['ADAPTER'] || 'postgres' if Rails.env.test?
