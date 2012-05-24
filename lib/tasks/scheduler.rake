task :fetch_names_and_emails => :environment do
  Account.fetch_missing_names_and_emails
end

task :periodic_restart do
  return if (Time.now.hour % 2) == 0
  require 'rest-client'
  p RestClient.post("https://:#{ENV['HEROKU_API_KEY']}@api.heroku.com/apps/adminium/ps/restart", {})
end

task :fill_tables_count => :environment do
  Account.where(tables_count: nil).find_each do |account|
    begin
      account.fill_tables_count
    rescue
      puts "failed for account ## #{account.id}"
    end
  end
end