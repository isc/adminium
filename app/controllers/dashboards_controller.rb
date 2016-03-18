class DashboardsController < ApplicationController
  
  before_action :fetch_permissions

  def show
    @db_size = @generic.db_size
    @table_list = @permissions.map {|key, value| key if value['read']}.compact if @permissions
    @table_sizes = @generic.table_sizes @table_list
    @table_counts = @generic.table_counts @table_list
    @widgets = current_account.widgets
    @widgets = @widgets.find_all {|w| @table_list.include? w.table} if @table_list
  end

  protected

  def fetch_permissions
    @permissions = current_collaborator.permissions unless admin?
  end

end
