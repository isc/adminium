task fetch_owner_emails: :environment do
  Account.fetch_missing_owner_emails
end

task statistical_computing: :environment do
  tables = {}
  columns = {}
  i = 0
  Account.where('encrypted_db_url is not null').where(adapter: 'postgres', deleted_at: nil).find_each do |account|
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
  end
  datas = {tables: tables, columns: columns} ; nil
  [:tables, :columns].each do |kind|
    datas[kind].to_a.sort{|a,b| b.last <=> a.last}.each do |a|
      puts "#{a.first}: #{a.last}"
    end ; nil 
  end ; nil
  puts datas
  datas = JSON.parse(datas)
end
