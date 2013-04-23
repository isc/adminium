namespace :settings do

  task :update_settings_keys => :environment do
    keys = REDIS.keys "account:*:settings:*"
    keys.each do |settings_key|
      account_part, model_name = settings_key.split(":settings:")
      updated_key_name = "#{account_part}:settings:#{model_name.tableize}"
      if settings_key != updated_key_name
        puts "#{settings_key} => #{updated_key_name}"
        REDIS.rename(settings_key, updated_key_name)
      end
    end
  end
  
  task :update_listings_keys => :environment do
    keys = REDIS.keys "account:*:settings:*"
    keys.each do |settings_key|
      parsed_key = JSON.parse(REDIS.get(settings_key))
      parsed_key["columns"]["listing"].each_with_index do |column, index|
        if column.include?('.')
          table_name, column = column.split('.')
          next if table_name == table_name.pluralize
          parsed_key["columns"]["listing"][index] = "#{table_name.pluralize}.#{column}"
          puts REDIS.set settings_key, parsed_key.to_json
          puts "#{settings_key} => #{parsed_key["columns"]["listing"][index]}"
        end
      end
    end
  end

  task :dump => :environment do
    keys = REDIS.keys "account:#{ENV['ACCOUNT_ID'] || ENV['DEMO_ACCOUNT_ID']}:settings:*"
    data = {}
    keys.each do |key|
      data[key] = REDIS.get key
    end
    File.open File.join(Rails.root, 'db', 'settings.yml'), 'w' do |f|
      f.write YAML.dump(data)
    end
  end

  task :load => :environment do
    data = YAML.load_file File.join(Rails.root, 'db', 'settings.yml')
    data.each do |key, value|
      key.gsub!(/account:\d+:/, "account:#{ENV['DEMO_ACCOUNT_ID']}:")
      REDIS.set key, value
    end
  end

  task :clear => :environment do
    keys = REDIS.keys "account:#{ENV['ACCOUNT_ID']}:settings:*"
    keys.each {|key| REDIS.del key}
  end

end
