class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Exception, with: :disconnect_on_exception
  rescue_from Generic::TableNotFoundException, with: :table_not_found
  rescue_from Sequel::DatabaseConnectionError, with: :global_db_error
  before_action :ensure_proper_subdomain
  before_action :require_account
  before_action :connect_to_db
  before_action :set_source_cookie
  after_action :cleanup_generic
  after_action :track_account_action
  around_action :tag_current_account

  helper_method :global_settings, :current_account, :current_user, :admin?, :current_account?, :resource_for

  private

  def global_settings
    @global_settings ||= Resource::Global.new session[:account]
  end

  def require_account
    session[:account] ||= 2 if Rails.env.development?
    redirect_to docs_url unless session[:account]
  end

  def require_user
    redirect_to root_path unless session[:user]
  end

  def connect_to_db
    if current_account.db_url.present?
      @generic = Generic.new current_account
      @tables = @generic.tables
    else
      redirect_to setup_database_connection_install_path
    end
  end

  def current_account?
    session[:account] ||= 2 if Rails.env.development?
    return !!current_account if session[:account]
    false
  end

  def current_account
    @account ||= Account.not_deleted.find session[:account] if session[:account]
  end

  def current_user
    @user ||= User.find session[:user] if session[:user]
  end

  def current_collaborator
    @collaborator ||= Collaborator.find(session[:collaborator]) if session[:collaborator]
  end

  def admin?
    (session[:account] && current_user.nil?) || current_collaborator&.is_administrator || (current_user&.heroku_provider? && current_collaborator.nil?)
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
    fail exception
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
    return if !Rails.env.production? || request.host_with_port['doctolib'] || request.host_with_port['adminium-staging.herokuapp']
    redirect_to host: 'www.adminium.io' if request.host_with_port != 'www.adminium.io'
  end

  def heroku_api
    @api ||= Heroku::API.new(api_key: session[:heroku_access_token], mock: Rails.env.test?) if session[:heroku_access_token]
  end

  def heroku_api_v3 method, path
    if session[:heroku_access_token]
      headers = {}
      headers['Accept'] = 'application/vnd.heroku+json; version=3'
      headers['Authorization'] = Base64.encode64(":#{session[:heroku_access_token]}\n").chomp
      headers['User-Agent'] = 'adminium-addon-client'
      resource = Excon.new 'https://api.heroku.com/'
      JSON.parse resource.request(method: method, path: path, headers: headers).data[:body]
    end
  end

  def track_account_action
    format = ".#{request.format.to_s.split('/').last}" if request.format != 'text/html'
    if session[:account]
      attrs = {account_id: session[:account], action: "#{params[:controller]}##{params[:action]}#{format}"}
      begin
        rows = Statistic.where(attrs).update_all ['value = value + 1, updated_at = ?', Time.current]
        Statistic.create attrs.merge(value: 1) if rows.zero?
      rescue PG::UniqueViolation
        retry
      end
    end
  end

  def valid_db_url?
    session[:account] && current_account.valid_db_url?
  end

  def tag_current_account
    logger.tagged("Account: #{session[:account] || 'No account'}") {yield}
  end
end
