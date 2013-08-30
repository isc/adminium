namespace :accounts do
  LIST_FILENAME = 'apps-list.json'
  
  task fetch_list: :environment do
    url = "https://#{HEROKU_MANIFEST['id']}:#{HEROKU_MANIFEST['api']['password']}@api.heroku.com/vendor/apps"
    File.open LIST_FILENAME, 'w' do |f|
      f.write RestClient.get(url)
    end
  end
  
  task :plan_summary do
    accounts = JSON.parse(File.read(LIST_FILENAME))
    puts "Total : #{accounts.size}"
    counts = Hash.new 0
    accounts.each do |account|
      counts[account['plan']] += 1
    end
    counts.each do |plan, count|
      puts "#{plan} : #{count}"
    end
  end
  
  task find_extra: :fetch_list do
    api_accounts = JSON.parse(File.read(LIST_FILENAME))
    Account.not_deleted.where(['plan != ?', Account::Plan::COMPLIMENTARY]).find_each do |account|
      api_account = api_accounts.detect {|a| a['heroku_id'] == account.heroku_id}
      puts "Missing account : #{account.inspect}" if api_account.nil?
      puts "Account with different plan : #{account.inspect} (#{api_account['plan']} expected)" if api_account && account.plan != api_account['plan']
    end
  end
  
end