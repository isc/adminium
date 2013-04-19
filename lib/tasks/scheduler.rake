task :fetch_names_and_emails => :environment do
  Account.fetch_missing_names_and_emails
end

task :periodic_restart do
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


task :statistical_computing => :environment do
  tables = {}
  columns = {}
  i = 0
  Account.where('encrypted_db_url is not null').where(adapter: 'postgres').where(deleted_at: nil)..find_each do |account|
    puts "#{i} #{account.id}"
    i += 1
    begin
      g=Generic.new(account)
      g.models.each do |model|
        tables[model.table_name] ||= 0
        tables[model.table_name] += 1
        model.columns.each do |column|
          columns[column.name] ||= 0
          columns[column.name] += 1
        end
      end
    rescue PG::Error
    end
  end ; nil
  datas = {tables: tables, columns: columns} ; nil
  [:tables, :columns].each do |kind|
    datas[kind].to_a.sort{|a,b| b.last <=> a.last}.each do |a|
      puts "#{a.first}: #{a.last}"
    end ; nil 
  end ; nil
  puts datas
  datas = JSON.parse(datas)

end