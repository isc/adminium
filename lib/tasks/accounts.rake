# frozen_string_literal: true

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

  task mark_extra_as_deleted: :fetch_list do
    api_accounts = JSON.parse(File.read(LIST_FILENAME))
    Account.not_deleted.where.not(plan: Account::Plan::COMPLIMENTARY).find_each do |account|
      api_account = api_accounts.detect {|a| a['heroku_id'] == account.heroku_id}
      if api_account.nil?
        puts "Missing account : #{account.id} - #{account.name} - #{account.plan}"
        account.update! plan: Account::Plan::DELETED, deleted_at: account.updated_at, db_url: nil
      end
    end
  end

  task migrate_searches: :environment do
    Account.where.not(plan: Account::Plan::DELETED, encrypted_db_url: nil).find_each do |account|
      begin
        puts account.id
        generic = Generic.new account
        generic.tables.each do |table|
          resource = Resource.new generic, table
          resource.filters.each do |name, conditions|
            account.searches.create name: name, conditions: conditions, table: table
          end
          resource.save
        end
        generic.cleanup
      rescue Sequel::DatabaseConnectionError, URI::InvalidURIError, Sequel::Error => e
        puts e
      end
    end
  end

  task cleanup_redis_for_deleted_accounts: :environment do
    Account.where.not(plan: Account::Plan::DELETED, encrypted_db_url: nil).find_each do |account|
      begin
        Generic.new account
      rescue Sequel::DatabaseConnectionError, URI::InvalidURIError
        keys = REDIS.keys("account:#{account.id}:*")
        REDIS.del(keys) if keys.any?
      end
    end
  end
end
