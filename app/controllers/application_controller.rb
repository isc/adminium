class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Exception, with: :disconnect_on_exception
  rescue_from Generic::TableNotFoundException, with: :table_not_found
  rescue_from Sequel::DatabaseConnectionError, with: :global_db_error
  before_filter :ensure_proper_subdomain
  before_filter :fixed_account
  before_filter :require_authentication
  before_filter :connect_to_db
  before_filter :set_source_cookie
  after_filter :cleanup_generic

  helper_method :global_settings, :current_account, :current_user, :admin?, :current_account?, :resource_for

  private

  def fixed_account
    # session[:account] = FIXED_ACCOUNT if session[:account].nil? && FIXED_ACCOUNT.present?
  end

  def global_settings
    @global_settings ||= Resource::Global.new session[:account]
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
    @account ||= Account.find session[:account] if session[:account]
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
    redirect_to :back, flash: {error: 'You need administrator privileges to access this page.'} unless admin?
  end

  def table_not_found exception
    redirect_to dashboard_url, flash: {error: "The table <b>#{exception.table_name}</b> cannot be found.".html_safe}
  end

  def cleanup_generic
    @generic.try :cleanup
  end
  
  def global_db_error exception
    msg = "There was a database error, it might be a problem with your database url. The error was : <pre>#{exception.message}</pre>".html_safe
    redirect_to edit_account_url, flash: {error: msg}
  end
  
  def disconnect_on_exception exception
    @generic.try :cleanup
    raise exception
  end
  
  def resource
    resource_for params[:id]
  end
  
  def resource_for table
    @resources ||= {} 
    @resources[table.to_sym] ||= Resource::Base.new @generic, table
  end
  
  def set_source_cookie
    cookies[:source] = params[:utm_source] if params[:utm_source].present?
  end
  
  def ensure_proper_subdomain
    return unless Rails.env.production?
    redirect_to params.merge(host: 'www.adminium.io') if request.host_with_port != 'www.adminium.io'
  end
  
end
