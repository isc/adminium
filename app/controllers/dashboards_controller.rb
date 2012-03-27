class DashboardsController < ApplicationController
  
  def show
    db_name = Generic::Base.connection.instance_variable_get('@config')[:database]
    @db_size = Generic::Base.connection.execute("select pg_database_size('#{db_name}') as fulldbsize").first['fulldbsize']
    @table_sizes = @generic.tables.map do |table|
      res = [table]
      res += Generic::Base.connection.execute("select pg_total_relation_size('#{table}') as fulltblsize, pg_relation_size('#{table}') as tblsize").first.values
      res << @generic.table(table).count
    end
  end
  
end