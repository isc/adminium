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
  
  protected
  
  def fetch_permissions
    return if admin?
    @permissions = current_collaborator.permissions
  end

end
