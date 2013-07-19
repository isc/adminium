class SessionsController < ApplicationController

  skip_before_filter :connect_to_db
  skip_before_filter :require_authentication, only: :create
  skip_before_filter :verify_authenticity_token, only: :create

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

end
