class UsersController < ApplicationController
  skip_before_action :require_account, only: %i(show apps)
  skip_before_action :connect_to_db

  def show
    respond_to do |format|
      format.html
      format.json do
        begin
          detect_apps
          render json: {apps: (@installed_apps.map {|a| a.attributes.slice('name', 'plan', 'heroku_id')} + @apps)}
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
    if current_user.heroku_provider?
      @apps = heroku_api.app.list.sort_by {|app| app['name'] }
      current_user.update total_heroku_apps: @apps.length
      @installed_apps = Account.where(deleted_at: nil, heroku_uuid: @apps.map {|app| app['id']}).order(:name)
      installed_heroku_ids = @installed_apps.map(&:heroku_uuid)
      @apps.delete_if {|app| installed_heroku_ids.include? app['id']}
    else
      @installed_apps = current_user.enterprise_accounts
    end
  end
end
