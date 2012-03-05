class GeneralSettingsController < ApplicationController

  def edit
  end

  def update
    global_settings.update params[:settings]
    redirect_to :back, :flash => {:success => 'Settings successully saved'}
  end

end