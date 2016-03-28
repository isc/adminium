class GeneralSettingsController < ApplicationController
  before_action :require_admin

  def update
    global_settings.update params[:settings]
    redirect_to :back, flash: {success: 'Settings successully saved'}
  end
end
