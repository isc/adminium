class UsersController < ApplicationController
  skip_before_action :require_account, only: %i(show apps)
  skip_before_action :connect_to_db

  def show
    respond_to do |format|
      format.html
      format.json do
        begin
          detect_apps
          render json: {apps: (@installed_apps.map {|a| a.attributes.slice('name', 'plan', 'heroku_uuid')} + @apps)}
        rescue Excon::Errors::Error => e
          render json: {error: JSON.parse(e.response.body)['message']}
        end
      end
    end
  end

  def apps
    detect_apps
  rescue Excon::Errors::Error
    @apps = [1]
  ensure
    render layout: false
  end

  private

  def detect_apps
    @apps, @installed_apps = [], []
    return unless current_user
    @installed_apps = current_user.enterprise_accounts
  end
end
