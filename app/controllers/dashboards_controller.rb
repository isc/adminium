class DashboardsController < ApplicationController

  before_filter :fetch_permissions

  def show
    @db_size = @generic.db_size
    table_list = @permissions.map {|key, value| key if value['read']}.compact if @permissions
    @table_sizes = @generic.table_sizes table_list
    @widgets = current_account.widgets
    # ObjectSpace.garbage_collect
    # GC.start()
    # render text: ObjectSpace.each_object(Class).map{|c|c.name}.find_all{|c| c.to_s.match 'Generic'}
  end

  def tables_count
    res = {}
    timeout = 5.seconds.from_now
    params[:tables].each do |table_name|
      res[table_name] = @generic.table(table_name).count
      break if Time.now > timeout
    end
    render json: res.to_json
  end

  protected

  def fetch_permissions
    return if admin?
    @permissions = current_collaborator.permissions
  end

end
