class SettingsController < ApplicationController

  def update
    settings = @generic.table(params[:id]).settings
    [:listing, :form, :show, :search].each do |type|
      param_key = "#{type}_columns".to_sym
      settings.columns[type] = params[param_key].keys.delete_if{|e|e == '_'} if params[param_key]
    end
    settings.filters = params[:filters].values if params.has_key?(:filters)
    settings.per_page = params[:per_page]
    settings.default_order = params[:default_order].join(' ') if params[:default_order].present?
    settings.enum_values = params[:enum_values] if params[:enum_values].present?
    settings.save
    redirect_to :back, flash: {success: 'Settings successfully saved.'}
  end

  def show
    @column = @generic.table(params[:id]).columns.detect{|c|c.name == params[:column_name]}
    render partial: '/settings/filter', locals: {filter: {'column' => @column.name, 'type' => @column.type}}
  end
  
  def values
    render :json => @generic.table(params[:id]).group(params[:column_name]).limit(50).order(params[:column_name]).count.keys
  end

end
