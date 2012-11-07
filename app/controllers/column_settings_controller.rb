class ColumnSettingsController < ApplicationController

  layout false
  helper_method :clazz, :column, :settings, :association_clazz

  def show
    @hidden = !settings.columns[:listing].include?(params[:column])
    @serialized = settings.columns[:serialized].include?(params[:column])
    @enum = settings.enum_values_for params[:column]
  end

  def create
    settings.update_column_options params[:column], params[:column_options]
    settings.update_enum_values params
    if params[:label_column]
      settings = @generic.table(params[:label_column][:table]).settings
      settings.label_column = params[:label_column][:label_column]
      settings.save
    end
    redirect_to :back
  end

  private
  def detect_association_column
    key = params[:column]
    if key.include? '.'
      parts = key.split('.')
      @assocation_table_name = parts.first.tableize
      @assocation_column_name = parts.join('.')
    end
  end

  def association_clazz
    return if @assocation_table_name.nil?
    @association_clazz ||= @generic.table(@assocation_table_name)
  end

  def clazz
    detect_association_column
    @clazz ||= @generic.table(params[:id])
  end

  def settings
    detect_association_column
    @settings ||= @generic.table(params[:id]).settings
  end

  def column
    detect_association_column
    @column ||= clazz.columns.detect{|c|c.name == params[:column]}
  end

end