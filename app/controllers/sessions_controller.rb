class SessionsController < ApplicationController
  skip_before_action :connect_to_db
  skip_before_action :require_account, only: %i(create destroy)
  skip_before_action :verify_authenticity_token, only: %i(create create_from_heroku)

  def create
    auth = request.env['omniauth.auth']
    user = User.find_by_provider_and_uid(auth.provider, auth.uid) || User.create_with_omniauth(auth)
    if (account = user.enterprise_accounts.first)
      collaborator = user.collaborators.find_by(account: account)
      session[:account] = account.id
      session[:user] = user.id
      session[:collaborator] = collaborator.id
      redirect_to root_url, notice: "Signed in as #{user.name} to #{current_account.name}."
    else
      redirect_to root_url, notice: 'Your Google account is not associated to any Enterprise Adminium account.'
    end
  end

  def switch_account
    collaborator = current_user.collaborators.find_by(account_id: params[:account_id])
    if collaborator&.account&.enterprise?
      session[:account] = collaborator.account_id
      session[:collaborator] = collaborator.id
    end
    redirect_to dashboard_url
  end

  def destroy
    session.clear
    redirect_to root_url, notice: 'Signed out!'
  end
end
