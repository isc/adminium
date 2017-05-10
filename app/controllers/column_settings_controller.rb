class ColumnSettingsController < ApplicationController
  layout false
  helper_method :column, :belongs_to_column?, :has_many_count_column?, :resource

  def show
    column = params[:column].to_sym
    @hidden = !resource.columns[params[:view].to_sym].include?(column)
    @serialized = resource.columns[:serialized].include?(column)
    @enum = resource.enum_values_for column
  end

  def create
    resource.update_column_options params[:column].to_sym, params[:column_options]
    resource.update_enum_values params
    if params[:label_column]
      resource = resource_for params[:label_column][:table]
      resource.label_column = params[:label_column][:label_column]
      resource.save
    end
    redirect_back fallback_location: resources_path(resource.table)
  end

  private

  def belongs_to_column?
    params[:column].include? '.'
  end

  def has_many_count_column?
    params[:column].starts_with? 'has_many/'
  end

  def column
    @column ||= resource.schema.detect {|name, _| name.to_s == params[:column]}.second
  end
end
