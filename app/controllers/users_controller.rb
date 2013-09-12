class UsersController < ApplicationController

  skip_before_filter :require_account, only: [:show, :apps]
  skip_filter :connect_to_db

  def show
    respond_to do |format|
      format.html
      format.json do
        begin
          detect_apps
          render json: {apps: (@installed_apps.map{|a|a.attributes.slice('name', 'plan', 'heroku_id')} + @apps)}
        rescue Heroku::API::Errors::ErrorWithResponse => e
          render json: {error: JSON.parse(e.response.data[:body])["error"]}
        end
      end
    end
  end
  
  def apps
    detect_apps
  rescue Heroku::API::Errors::ErrorWithResponse
    @apps = [1]
  ensure
    render layout: false
  end
  
  private
  def detect_apps
    @apps = []
    @installed_apps = []
    if current_user
      if current_user.heroku_provider?
        @apps = heroku_api.get_apps.data[:body].sort{|app1,app2| app1['name'] <=> app2['name']}
        current_user.update_attribute :total_heroku_apps, @apps.length
        account_heroku_ids = @apps.map{|app| "app#{app['id']}@heroku.com" }
        @installed_apps = Account.where(deleted_at: nil, heroku_id: account_heroku_ids).order(:name)
        installed_heroku_ids = @installed_apps.map{|account| account.heroku_id_only}
        @apps.delete_if {|app| installed_heroku_ids.include? app['id'].to_s }
      else
        @installed_apps = current_user.enterprise_accounts
      end
    end
  end

end
