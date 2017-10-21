namespace :settings do
  task dump: :environment do
    keys = REDIS.keys "account:#{ENV['ACCOUNT_ID'] || ENV['DEMO_ACCOUNT_ID']}:settings:*"
    data = {}
    keys.each do |key|
      data[key] = REDIS.get key
    end
    File.open Rails.root.join('db', 'settings.yml'), 'w' do |f|
      f.write YAML.dump(data)
    end
  end

  task load: :environment do
    data = YAML.load_file Rails.root.join('db', 'settings.yml')
    data.each do |key, value|
      key.gsub!(/account:\d+:/, "account:#{ENV['DEMO_ACCOUNT_ID']}:")
      REDIS.set key, value
    end
  end

  task clear: :environment do
    keys = REDIS.keys "account:#{ENV['ACCOUNT_ID']}:settings:*"
    keys.each {|key| REDIS.del key}
  end
end
