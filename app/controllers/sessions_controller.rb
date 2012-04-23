class SessionsController < ApplicationController

  skip_before_filter :connect_to_db
  skip_before_filter :require_authentication, only: :create

  def create
    auth = request.env['omniauth.auth']
    user = User.find_by_provider_and_uid(auth['provider'], auth['uid']) || User.create_with_omniauth(auth)
    if user.collaborators.any?
      collaborator = user.collaborators.first
      session[:account] = collaborator.account_id
      session[:user] = user.id
      session[:collaborator] = collaborator.id
      redirect_to root_url, notice: "Signed in as #{user.name} to #{current_account.name}."
    else
      redirect_to root_url, notice: 'Your google account is not associated to any Adminium account.'
    end
  end

  def switch_account
    collaborator = current_user.collaborators.where(:account_id => params[:account_id]).first
    if collaborator
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
