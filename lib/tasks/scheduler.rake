task fetch_owner_emails: :environment do
  Account.fetch_missing_owner_emails
end

task statistical_computing: :environment do
  done_ids = [2379, 2378, 2377, 2376, 2375, 2374, 2370, 2368, 2367, 2366]
  results = []
  Account.where('encrypted_db_url is not null').where(deleted_at: nil).where('plan is not "petproject"').order('id desc').limit(30).all.each do |account|
    puts account.name
    done_ids.push(account.id)
    begin
      g = Generic.new account, timeout: 20, connect_timeout: 3, read_timeout: 5, max_connections: 10
      g.tables.each do |table|
        g.schema(table).each do |column|
          name = column.first
          type = column.last[:type]
          results.push [account.name, table, name, type]
        end
      end
    rescue Sequel::DatabaseConnectionError, Sequel::DatabaseError => e
      puts account.name
      puts e.inspect
    ensure
      g.try :cleanup
    end
  end
end
