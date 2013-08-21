class SessionsController < ApplicationController

  skip_before_filter :connect_to_db
  skip_before_filter :require_account, only: [:create, :create_from_heroku, :login_heroku_app]
  skip_before_filter :verify_authenticity_token, only: [:create, :create_from_heroku]

  def create_from_heroku
    session[:heroku_access_token] = request.env['omniauth.auth']['credentials']['token']
    if current_account && current_account.db_url.blank?
      configure_db_url
    else
      user_infos = heroku_api.get_user.data[:body]
      user = User.find_by_provider_and_uid('heroku', user_infos['id']) || User.create_with_heroku(user_infos)
      session[:user] = user.id
      redirect_to user_path
    end
  end
  
  def create
    auth = request.env['omniauth.auth']
    user = User.find_by_provider_and_uid(auth['provider'], auth['uid']) || User.create_with_omniauth(auth)
    if account = user.enterprise_accounts.first
      collaborator = user.collaborators.where(account_id: account.id).first
      session[:account] = account.id
      session[:user] = user.id
      session[:collaborator] = collaborator.id
      track_sign_on account
      redirect_to root_url, notice: "Signed in as #{user.name} to #{current_account.name}."
    else
      redirect_to root_url, notice: 'Your Google account is not associated to any Enterprise Adminium account.'
    end
  end
  
  def login_heroku_app
    apps = heroku_api.get_apps.data[:body]
    app_id = params[:id]
    app = apps.detect{|app| app['id'].to_s == app_id}
    if app
      account = Account.find_by_heroku_id("app#{app_id}@heroku.com")
      session[:account] = account.id
      track_sign_on account
      redirect_to root_url, notice: "Signed in to #{current_account.name}."
    else
      redirect_to user_path, error: "you are not unauthorized to access this app because it looks like you are not a collaborator of this app !"
    end
  end

  def switch_account
    collaborator = current_user.collaborators.where(account_id: params[:account_id]).first
    if collaborator && collaborator.account.enterprise?
      session[:account] = collaborator.account_id
      session[:collaborator] = collaborator.id
      track_sign_on collaborator.account
    end
    redirect_to dashboard_url
  end

  def destroy
    session.clear
    redirect_to root_url, notice: 'Signed out!'
  end
  
  private
  def track_sign_on account
    SignOn.create account_id: account.id, plan: account.plan,
      remote_ip: request.remote_ip, kind: SignOn::Kind::GOOGLE, user_id: session[:user]
  end
  
  def configure_db_url
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

end
