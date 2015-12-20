class InstallsController < ApplicationController
  
  skip_filter :connect_to_db, unless: :valid_db_url?
  
  def setup_database_connection
    @db_urls = session[:db_urls] if session[:db_urls]
  end
  
  def invite_team
    if current_user.try :heroku_provider?
      @heroku_collaborators = heroku_api.get_collaborators(current_account.name).data[:body]
      @heroku_collaborators.delete_if {|c| c['email'] == current_user.email}
    else
      redirect_to dashboard_path
    end
  rescue Heroku::API::Errors::ErrorWithResponse
    redirect_to dashboard_path
  end
  
  def send_email_team
    redirect_opts = {}
    if params[:emails] && params[:emails].length > 0
      CollaboratorMailer.welcome_heroku_collaborator(params[:emails], current_account, current_user).deliver
    end
  rescue => ex
    notify_airbrake(ex)
    redirect_opts = {flash: {error: 'Sorry but we failed to send the email to everyone :('}}
  ensure
    redirect_to dashboard_path, redirect_opts
  end
  
end
