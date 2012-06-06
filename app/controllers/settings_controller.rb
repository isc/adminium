class SettingsController < ApplicationController

  def update
    settings = @generic.table(params[:id]).settings
    [:listing, :form, :show, :search, :serialized, :export].each do |type|
      param_key = "#{type}_columns".to_sym
      settings.columns[type] = params[param_key].delete_if {|e|e.empty?} if params.has_key? param_key
    end
    [:enum_values, :validations].each do |setting|
      settings.send "#{setting}=", params[setting].delete_if {|e|e.empty?} if params.has_key? setting
    end
    settings.per_page = params[:per_page] if params[:per_page]
    settings.label_column = params[:label_column] if params[:label_column]
    settings.default_order = params[:default_order].join(' ') if params[:default_order].present?
    settings.save
    if params[:back_to]
      redirect_to params[:back_to]
      return
    end
    redirect_to :back, flash: {success: 'Settings successfully saved.'}
  end

  def update_advanced_search
    if params[:name] && params[:filters]
      settings = @generic.table(params[:id]).settings
      settings.filters[params[:name]] = params[:filters].values
      settings.save
    end
    redirect_to resources_path(params[:id], asearch: params[:name])
  end

  def destroy
    settings = @generic.table(params[:id]).settings
    settings.filters.delete params[:name]
    settings.save
    render nothing: true
  end

  def show
    @column = @generic.table(params[:id]).columns.detect{|c|c.name == params[:column_name]}
    render partial: '/settings/filter', locals: {filter: {'column' => @column.name, 'type' => @column.type}}
  end

  def values
    render json: @generic.table(params[:id]).select("distinct(#{params[:column_name]})").
      limit(50).order(params[:column_name]).pluck(params[:column_name])
  end

  def columns
    render json: @generic.table(params[:table]).column_names
  end

end
