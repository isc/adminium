class GeneralSettingsController < ApplicationController

  def edit
  end

  def update
    global_settings.update params[:settings]
    redirect_to :back
  end

end