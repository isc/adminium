class DashboardsController < ApplicationController

  def show
    db_name = Generic::Base.connection.instance_variable_get('@config')[:database]
    if @generic.mysql?
      sql = "select sum(data_length + index_length) as fulldbsize FROM information_schema.TABLES WHERE table_schema = '#{db_name}'"
      @db_size = Generic::Base.connection.execute(sql).first.first
      @table_sizes = Generic::Base.connection.execute "select table_name, data_length + index_length, data_length from information_schema.TABLES WHERE table_schema = '#{db_name}'"
      @table_sizes.each {|table_row| table_row << @generic.table(table_row.first).count }
    else
      sql = "select pg_database_size('#{db_name}') as fulldbsize"
      @db_size = Generic::Base.connection.execute(sql).first['fulldbsize']
      @table_sizes = @generic.tables.map do |table|
        res = [table]
        res += Generic::Base.connection.execute("select pg_total_relation_size('#{table}') as fulltblsize, pg_relation_size('#{table}') as tblsize").first.values
        res << @generic.table(table).count
      end
    end
  end

end
