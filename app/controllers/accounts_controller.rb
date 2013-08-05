class AccountsController < ApplicationController

  before_filter :require_admin, except: :create
  skip_filter :connect_to_db
  skip_filter :require_account, only: :create

  def edit
    @account = current_account
  end
  
  # wip
  #def create
  #  app = params[:app_id]
  #  resp = heroku_api.post_addon(app, "adminium:petproject")
  #  resp.data[:body] == "Installed"
  #  account = Account.find_by_name app
  #  config = heroku_api.get_config_vars(app).data[:body]
  #  render text: config["DATABASE_URL"]
  #end
  
  def update_db_url_from_heroku_api
    access_token = request.env['omniauth.auth']['credentials']['token']
    apps = heroku_api.get_apps.data[:body]
    app_id = current_account.heroku_id.match(/\d+/).to_s
    app = apps.detect{|app| app['id'].to_s == app_id}
    app_name = app["name"]
    config_vars = heroku_api.get_config_vars(app_name).data[:body]
    @db_urls = db_urls config_vars
    if @db_urls.length == 1
      current_account.db_url = @db_urls.first[:value]
      current_account.db_url_setup_method = 'oauth'
      current_account.save
      redirect_to dashboard_path
    else
      session[:db_urls] = @db_urls
      redirect_to doc_path(:missing_db_url)
    end
  end
  
  def db_urls config_vars
    db_urls = []
    config_vars.keys.find_all {|key| key.match(/(HEROKU_POSTGRESQL_.*_URL)|(.*DATABASE_URL.*)/)}.each do |key|
      if !db_urls.map{|d| d[:value]}.include?( config_vars[key])
        db_urls << {:key => key, :value => config_vars[key]}
      end
    end
    db_urls
  end

  def update
    if params[:db_key] && session[:db_urls].present?
      db_url = session[:db_urls].detect{|db_url| db_url[:key] == params[:db_key]}
      params[:account] ||= {}
      params[:account][:db_url] = db_url[:value]
      session[:db_urls]
      params[:account][:db_url_setup_method] = 'oauth'
    else
      params[:account][:db_url_setup_method] = 'web'
    end
    if current_account.update_attributes! params[:account]
      if params[:install]
        redirect_to dashboard_path
      else
        redirect_to edit_account_path, notice: 'Changes saved.'
      end
    else
      render :edit
    end
  end

  def cancel_tips
    current_account.tips_opt_in = false
    res = current_account.save
    render json: res
  end

  def db_url_presence
    render json: current_account.db_url.present?
  end

end
