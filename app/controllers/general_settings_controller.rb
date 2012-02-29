class GeneralSettingsController < ApplicationController

  def edit
  end

  def update
    Settings::Global.update params[:settings]
    redirect_to :back, :flash => {:success => 'Settings successully saved'}
  end

end