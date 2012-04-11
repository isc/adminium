class DashboardsController < ApplicationController
  
  before_filter :fetch_permissions
  
  def show
    @db_size = @generic.db_size
    table_list = @permissions.map {|key, value| key if value['read']}.compact if @permissions
    @table_sizes = @generic.table_sizes table_list
  end
  
  protected
  
  def fetch_permissions
    return unless current_user
    @permissions = current_user.permissions(current_account)
  end

end
