class SettingsController < ApplicationController

  def update
    [:listing, :form, :show, :search, :serialized, :export].each do |type|
      param_key = "#{type}_columns".to_sym
      resource.columns[type] = params[param_key].delete_if(&:empty?) if params.has_key? param_key
    end
    [:validations].each do |setting|
      resource.send "#{setting}=", params[setting].delete_if(&:empty?) if params.has_key? setting
    end
    resource.per_page = params[:per_page] if params[:per_page]
    resource.label_column = params[:label_column] if params[:label_column]
    resource.default_order = params[:default_order].join(' ') if params[:default_order].present?
    resource.save
    if params[:back_to]
      redirect_to params[:back_to]
    else
      redirect_to :back, flash: {success: 'Settings successfully saved.'}
    end
  end

  def show
    column_name = params[:column_name].to_sym
    @column = resource.column_info column_name
    render partial: '/settings/filter', locals: {filter: {'column' => column_name, 'type' => @column[:type]}}
  end

  def values
    column_name = params[:column_name].to_sym
    render json: @generic.table(params[:id]).select(column_name).distinct.
      limit(50).order(column_name).map{|d| d[column_name]}
  end

  def columns
    render json: resource_for(params[:table]).column_names.sort
  end

end
