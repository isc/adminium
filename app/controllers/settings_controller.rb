class SettingsController < ApplicationController

  def update
    settings = Generic.table(params[:id]).settings
    settings.columns = params[:columns].keys
    settings.filters = params[:filters].values if params.has_key?(:filters)
    settings.per_page = params[:per_page]
    settings.save
    redirect_to :back
  end

  def show
    @column = Generic.table(params[:id]).columns.detect{|c|c.name == params[:column_name]}
    render :partial => "/settings/filter", locals: {filter: {'column' => @column.name, 'type' => @column.type}}
  end

end
