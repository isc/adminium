task fetch_owner_emails: :environment do
  Account.fetch_missing_owner_emails
end

task statistical_computing: :environment do
  results = []
  Account.where('encrypted_db_url is not null').where(deleted_at: nil).find_each do |account|
    begin
      g=Generic.new account, timeout: 20, connect_timeout: 3, read_timeout: 5, max_connections: 10
      g.tables.each do |table|
        g.schema(table).each do |column|
          name = column.first
          type = column.last[:type]
          results.push [account.name, table, name, type]
        end
      end
    rescue Sequel::DatabaseConnectionError => e
      puts account.name
      puts e.inspect
    ensure
      g.try :cleanup
    end
  end ; nil
end