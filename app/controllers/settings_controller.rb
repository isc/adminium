class SettingsController < ApplicationController
  def update
    column_selection_update =
      %i(listing form show search serialized export).map do |type|
        param_key = "#{type}_columns".to_sym
        [type, params[param_key].delete_if(&:empty?)] if params.key? param_key
      end.compact.to_h
    resource.update_column_selection column_selection_update
    table_configuration.update! table_configuration_params if table_configuration.present?
    resource.per_page = params[:per_page] if params[:per_page]
    resource.save
    redirect_back fallback_location: resources_path(resource.table), success: 'Settings successfully saved'
  end

  def show
    column_name = params[:column_name].to_sym
    if params[:assoc]
      assoc_resource = resource_for(resource.belongs_to_association(params[:assoc].to_sym)[:referenced_table])
      @column = assoc_resource.column_info column_name
    else
      @column = resource.column_info column_name
    end
    render partial: '/settings/filter', locals:
      {filter: {'column' => column_name, 'type' => (@column[:type] || @column[:db_type]), 'assoc' => params[:assoc]}}
  end

  def values
    column_name = params[:column_name].to_sym
    render json: @generic.table(params[:id]).select(column_name).distinct
      .limit(50).order(column_name).map { |d| d[column_name].to_s }
  end

  def columns
    names = case params[:chart_type]
            when 'TimeChartWidget'
              resource_for(params[:table]).date_column_names
            when 'PieChartWidget'
              resource_for(params[:table]).pie_chart_column_names
            when 'StatChartWidget'
              resource_for(params[:table]).stat_chart_column_names
            else
              resource_for(params[:table]).column_names
            end
    render json: names.sort
  end

  private

  def table_configuration
    table_configuration_for(resource.table)
  end

  def table_configuration_params
    res = {}
    if params[:polymorphic_associations]
      res[:polymorphic_associations] = params[:polymorphic_associations].delete_if(&:empty?).map {|p| JSON.parse(p)}
    end
    res[:label_column] = params[:label_column].presence if params[:label_column]
    res[:validations] = params[:validations].delete_if(&:empty?) if params[:validations]
    res[:default_order] = params[:default_order].join(' ').strip if params[:default_order].present?
    res
  end
end
