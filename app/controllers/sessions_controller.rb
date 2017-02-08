class SessionsController < ApplicationController
  include AppInstall

  skip_before_action :connect_to_db
  skip_before_action :require_account, only: [:create, :create_from_heroku, :login_heroku_app, :destroy]
  skip_before_action :verify_authenticity_token, only: [:create, :create_from_heroku]

  def create_from_heroku
    session[:heroku_access_token] = request.env['omniauth.auth']['credentials']['token']
    unless session[:user]
      user_infos = heroku_api.get_user.data[:body]
      user = User.find_by_provider_and_uid('heroku', user_infos['id']) || User.create_with_heroku(user_infos)
      session[:user] = user.id
    end
    if current_account && current_account.db_url.blank?
      detect_app_name
      set_profile
      set_collaborators
      current_account.save
      redirect_to configure_db_url('oauth') ? dashboard_path : setup_database_connection_install_path
    else
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
      track_sign_on account, SignOn::Kind::GOOGLE
      redirect_to root_url, notice: "Signed in as #{user.name} to #{current_account.name}."
    else
      redirect_to root_url, notice: 'Your Google account is not associated to any Enterprise Adminium account.'
    end
  end

  def login_heroku_app
    apps = heroku_api.get_apps.data[:body]
    app_id = params[:id].match(/\d+/).to_s
    app = apps.detect {|app| app['id'].to_s == app_id}
    if app
      @account = Account.find_by_heroku_id("app#{app_id}@heroku.com")
      session[:account] = @account.id
      unless current_account.app_profile
        set_profile
        set_collaborators
        current_account.save!
      end
      collaborator = current_user.collaborators.where(account_id: current_account.id).first
      session[:collaborator] = collaborator&.id
      track_sign_on current_account, SignOn::Kind::HEROKU_OAUTH
      redirect_to root_url, notice: "Signed in to #{current_account.name}."
    else
      redirect_to user_path, error: 'You are not unauthorized to access this app because it looks like you are not a collaborator of this app !'
    end
  end

  def switch_account
    collaborator = current_user.collaborators.where(account_id: params[:account_id]).first
    if collaborator && collaborator.account.enterprise?
      session[:account] = collaborator.account_id
      session[:collaborator] = collaborator.id
      track_sign_on collaborator.account, SignOn::Kind::GOOGLE
    end
    redirect_to dashboard_url
  end

  def destroy
    session.clear
    redirect_to root_url, notice: 'Signed out!'
  end

  private

  def track_sign_on account, kind
    SignOn.create account_id: account.id, plan: account.plan,
                  remote_ip: request.remote_ip, kind: kind, user_id: session[:user]
  end
end
