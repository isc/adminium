class DashboardsController < ApplicationController

  before_filter :fetch_permissions

  def show
    @db_size = @generic.db_size
    table_list = @permissions.map {|key, value| key if value['read']}.compact if @permissions
    @table_sizes = @generic.table_sizes table_list
    @widgets = current_account.widgets
  end

  def tables_count
    res = {}
    timeout = 5.seconds.from_now
    params[:tables].each do |table_name|
      res[table_name] = (@generic.table(table_name).count rescue 0)
      break if Time.now > timeout
    end
    render json: res
  end

  protected

  def fetch_permissions
    @permissions = current_collaborator.permissions unless admin?
  end

end
