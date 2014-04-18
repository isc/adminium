class DashboardsController < ApplicationController
  
  TIMEOUT_VALUE = 0.5

  before_filter :fetch_permissions

  def show
    @db_size = @generic.db_size
    @table_list = @permissions.map {|key, value| key if value['read']}.compact if @permissions
    @table_sizes = @generic.table_sizes @table_list
    @widgets = current_account.widgets.find_all {|w| @table_list.include? w.table}
  end

  def tables_count
    res = {}
    timeout = 5.seconds.from_now
    params[:tables].each do |table_name|
      begin
        Timeout::timeout(TIMEOUT_VALUE) do
          res[table_name] = (@generic.table(table_name).count rescue 0)
        end
      rescue Timeout::Error => e
        Rails.logger.warn "table #{table_name} took too long"
        if @generic.postgresql?
          res[table_name] = "~#{@generic.loose_count(table_name)}"
        else
          res[table_name] = "?"
        end
      end
      break if Time.now > timeout
    end
    render json: res
  end

  protected

  def fetch_permissions
    @permissions = current_collaborator.permissions unless admin?
  end

end
