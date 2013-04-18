class ColumnSettingsController < ApplicationController

  layout false
  helper_method :column, :resource, :association_clazz, :has_many_count_column

  def show
    @hidden = !resource.columns[:listing].include?(params[:column])
    @serialized = resource.columns[:serialized].include?(params[:column])
    @enum = resource.enum_values_for params[:column]
  end

  def create
    resource.update_column_options params[:column], params[:column_options]
    resource.update_enum_values params
    if params[:label_column]
      resource = Resource::Base.new @generic, params[:label_column][:table]
      resource.label_column = params[:label_column][:label_column]
      resource.save
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

  def column
    @column ||= resource.schema.detect{|name, _|name.to_s == params[:column]}.second
  end

end
