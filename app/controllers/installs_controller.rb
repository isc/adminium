class InstallsController < ApplicationController
  skip_before_action :connect_to_db, unless: :valid_db_url?

  def setup_database_connection
    @db_urls = session[:db_urls] if session[:db_urls]
  end

  def invite_team
    if current_user&.heroku_provider?
      @heroku_collaborators = heroku_api.collaborator.list(current_account.name)
      @heroku_collaborators.delete_if {|c| c['user']['email'] == current_user.email}
    else
      redirect_to dashboard_path
    end
  rescue Excon::Errors::Error
    redirect_to dashboard_path
  end

  def send_email_team
    if params[:emails]&.any?
      CollaboratorMailer.welcome_heroku_collaborator(params[:emails], current_account, current_user).deliver_later
    end
    redirect_to dashboard_path
  rescue => exception
    notify_airbrake exception
    redirect_to dashboard_path, error: 'Sorry but we failed to send the email to everyone :('
  end
end
