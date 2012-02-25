class SettingsController < ApplicationController

  def update
    settings = Generic.table(params[:id]).settings
    settings.columns = params[:columns].keys
    settings.filters = params[:filters].values
    settings.per_page = params[:per_page]
    settings.save
    redirect_to :back
  end

  def show
    @column = Generic.table(params[:id]).columns.detect{|c|c.name == params[:column_name]}
    render :partial => "/settings/filters/#{@column.type}", :locals => {:filter => {'column' => @column.name}}
  end

end