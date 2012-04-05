class SettingsController < ApplicationController

  def update
    settings = @generic.table(params[:id]).settings
    [:listing, :form, :show, :search, :serialized].each do |type|
      param_key = "#{type}_columns".to_sym
      settings.columns[type] = params[param_key].delete_if {|e|e.empty?} if params.has_key? param_key
    end
    settings.filters = params[:filters].values if params.has_key?(:filters)
    settings.per_page = params[:per_page] if params[:per_page]
    settings.label_column = params[:label_column] if params[:label_column]
    settings.default_order = params[:default_order].join(' ') if params[:default_order].present?
    [:enum_values, :validations].each do |setting|
      settings.send "#{setting}=", params[setting].delete_if {|e|e.empty?} if params.has_key? setting
    end
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
