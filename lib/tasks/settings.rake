namespace :settings do

  task :migrate_enum_data => :environment do
    keys = REDIS.keys "account:*:settings:*"
    keys.each do |settings_key|
      account_settings = REDIS.get settings_key
      settings = JSON.parse(account_settings)
      if settings["enum_values"].is_a?(Array)
        settings["enum_values"].map do |setting|
          values = setting["values"]
          res = {}
          values.split("\n").each do |t|
            split = t.split(':').map &:strip
            res[split[0]] = {'color' => '#3366FF', 'label' => split[1]}
          end
          setting["values"] = res
        end
        puts settings
        REDIS.set settings_key, settings.to_json
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
