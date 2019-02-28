class SettingsController < ApplicationController
  def update
    %i(listing form show search serialized export).each do |type|
      param_key = "#{type}_columns".to_sym
      resource.columns[type] = params[param_key].delete_if(&:empty?) if params.key? param_key
    end
    table_configuration.update! table_configuration_params if table_configuration.present?
    resource.per_page = params[:per_page] if params[:per_page]
    resource.label_column = params[:label_column].presence if params.key? :label_column
    resource.default_order = params[:default_order].join(' ') if params[:default_order].present?
    resource.save
    redirect_back fallback_location: resources_path(resource.table), flash: {success: 'Settings successfully saved'}
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
    current_account.table_configurations.find_or_create_by(table: resource.table)
  end

  def table_configuration_params
    res = {}
    if params[:polymorphic_associations]
      res[:polymorphic_associations] = params[:polymorphic_associations].delete_if(&:empty?).map {|p| JSON.parse(p)}
    end
    res[:validations] = params[:validations].delete_if(&:empty?) if params[:validations]
    res
  end
end
