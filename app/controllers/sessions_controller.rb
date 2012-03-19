class SessionsController < ApplicationController
  
  skip_before_filter :connect_to_db
  skip_before_filter :require_authentication, only: :create
  
  def create
    auth = request.env['omniauth.auth']
    user = User.find_by_provider_and_uid(auth['provider'], auth['uid']) || User.create_with_omniauth(auth)
    if user.accounts.any?
      session[:account] = user.accounts.first.id
      session[:user] = user.id
      redirect_to root_url, notice: "Signed in as #{user.name} to #{current_account.name}."
    else
      redirect_to root_url, notice: 'Your google account is not associated to any DbInsights account.'
    end
  end

  def switch_account
    account_id = params[:account_id].to_i
    session[:account] = account_id if current_user.accounts.map(&:id).include? account_id
    redirect_to root_url
  end

  def destroy
    session[:user] = session[:account] = nil
    redirect_to root_url, notice: 'Signed out!'
  end
  
end
