class GeneralSettingsController < ApplicationController

  def edit
  end

  def update
    Settings::Global.update params[:settings]
    redirect_to :back
  end

end