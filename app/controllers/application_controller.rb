class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Generic::TableNotFoundException, with: :table_not_found
  rescue_from PGError, Mysql2::Error, :with => :global_db_error
  before_filter :fixed_account
  before_filter :require_authentication
  before_filter :connect_to_db
  after_filter :cleanup_generic

  helper_method :global_settings, :current_account, :current_user, :admin?, :current_account?

  private

  def fixed_account
    # session[:account] = FIXED_ACCOUNT if session[:account].nil? && FIXED_ACCOUNT.present?
  end

  def global_settings
    @global_settings ||= Settings::Global.new(session[:account])
  end

  def require_authentication
    redirect_to docs_url unless session[:account]
  end

  def connect_to_db
    if current_account.db_url.present?
      @generic = Generic.new current_account
      @tables = @generic.tables
    else
      redirect_to doc_url(:missing_db_url)
    end
  end

  def current_account?
    return !!current_account if session[:account]
    return false
  end

  def current_account
    @account ||= Account.find session[:account]
  end

  def current_user
    @user ||= User.find session[:user] if session[:user]
  end

  def current_collaborator
    @collaborator ||= Collaborator.find(session[:collaborator]) if session[:collaborator]
  end

  def admin?
    (session[:account] && current_user.nil?) || current_collaborator.try(:is_administrator)
  end

  def require_admin
    redirect_to dashboard_url unless admin?
  end

  def table_not_found exception
    redirect_to edit_account_path, flash: {error: "The table <b>#{exception.table_name}</b> cannot be found.".html_safe}
  end

  def cleanup_generic
    @generic.try :cleanup
  end
  
  def global_db_error exception
    redirect_to edit_account_url, :flash => {:error => "There was a database error, it might be a problem with your database url. The error was : <pre>#{exception.message}</pre>".html_safe}
  end

end
