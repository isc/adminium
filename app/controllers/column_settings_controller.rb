class ColumnSettingsController < ApplicationController

  layout false
  helper_method :clazz, :column, :settings

  def show
    @hidden = !settings.columns[:listing].include?(column.name)
    @serialized = settings.columns[:serialized].include?(column.name)
  end

  def create
    settings.update_column_options column.name, params[:column_options]
    redirect_to :back
  end

  private
  def clazz
    @clazz ||= @generic.table(params[:id])
  end
  def settings
    @settings ||= @generic.table(params[:id]).settings
  end

  def column
    @column ||= clazz.columns.detect{|c|c.name == params[:column]}
  end

end