class GeneralSettingsController < ApplicationController
  before_action :require_admin

  def update
    global_settings.update params[:settings]
    redirect_back fallback_location: edit_account_path, flash: {success: 'Settings successully saved'}
  end
end
