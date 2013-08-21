class UsersController < ApplicationController

  skip_before_filter :require_account, only: :show
  skip_filter :connect_to_db

  def show
    if session[:heroku_access_token]
      @apps = heroku_api.get_apps.data[:body].sort{|app1,app2| app1['name'] <=> app2['name']}
      account_heroku_ids = @apps.map{|app| "app#{app['id']}@heroku.com" }
      @installed_apps = Account.where(heroku_id: account_heroku_ids)
      installed_heroku_ids = @installed_apps.map{|account| account.heroku_id.match(/\d+/).to_s}
      @apps.delete_if {|app| installed_heroku_ids.include? app['id'].to_s }
    else
      redirect_to root_path
    end
  end

end
