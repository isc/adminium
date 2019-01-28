class DashboardsController < ApplicationController
  before_action :fetch_permissions

  def show
    @db_size = @generic.db_size
    @table_list = @permissions.map {|key, value| key if value['read']}.compact if @permissions
    @table_sizes = @generic.table_sizes @table_list
    @table_counts = @generic.table_counts @table_list
    @widgets = current_account.widgets
    @widgets = @widgets.find_all {|w| @table_list.include? w.table} if @table_list
    @comments = @generic.table_comments(@table_list).index_by { |r| r[:relname] }
  end

  def settings
    @settings = @generic.db['show all'].to_a
    @settings.select! {|setting| setting[:name][params[:filter]]} if params[:filter].present?
  end

  def bloat
    @rows = @generic.db[IO.read(Rails.root.join('lib', 'btree_bloat.sql'))].all
  end

  protected

  def fetch_permissions
    @permissions = current_collaborator.permissions unless admin?
  end
end
