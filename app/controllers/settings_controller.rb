class SettingsController < ApplicationController

  def update
    settings = Generic.table(params[:id]).settings
    settings.columns = params[:columns].keys
    settings.per_page = params[:per_page]
    settings.save
    redirect_to :back
  end
end