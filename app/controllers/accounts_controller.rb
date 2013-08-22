class AccountsController < ApplicationController

  before_filter :require_admin, except: :create
  skip_filter :connect_to_db
  skip_filter :require_account, only: :create

  def edit
    @account = current_account
  end
  
  def create
    app_name = params[:name]
    app_id = params[:app_id]
    resp = heroku_api.post_addon(app_name, "adminium:petproject")
    if resp.data[:body]["status"] == "Installed"
      @account = Account.find_by_heroku_id "app#{app_id}@heroku.com"
      session[:account] = @account.id
      current_account.name = app_name
      config = heroku_api.get_config_vars(app_name).data[:body]
      @db_urls = db_urls heroku_api.get_config_vars(app_name).data[:body]
      if @db_urls.length == 1
        current_account.db_url = @db_urls.first[:value]
        current_account.db_url_setup_method = 'self-create'
      else
        session[:db_urls] = @db_urls
      end
      current_account.save
      render json: {success: true}
    else
      render json: {success: false}
    end
  rescue
    render json: {sucess: false}
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
