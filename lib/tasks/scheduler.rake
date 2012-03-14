task :fetch_names_and_emails => :environment do
  Account.fetch_missing_names_and_emails
end
