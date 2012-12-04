class ColumnSettingsController < ApplicationController

  layout false
  helper_method :clazz, :column, :settings, :association_clazz, :has_many_count_column

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
    if params[:column].include? '.'
      @association_table_name = params[:column].split('.').first.tableize
    end
  end

  def association_clazz
    return if @association_table_name.nil?
    @association_clazz ||= @generic.table @association_table_name
  end
  
  def has_many_count_column
    params[:column].starts_with? 'has_many/'
  end

  def clazz
    detect_association_column
    @clazz ||= @generic.table params[:id]
  end

  def settings
    @settings ||= clazz.settings
  end

  def column
    @column ||= clazz.columns.detect{|c|c.name == params[:column]}
  end

end
