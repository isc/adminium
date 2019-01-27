class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Exception, with: :disconnect_on_exception
  rescue_from Generic::TableNotFoundException, with: :table_not_found
  rescue_from Sequel::DatabaseError, with: :statement_timeouts
  rescue_from Sequel::DatabaseConnectionError, with: :global_db_error
  before_action :ensure_proper_subdomain
  before_action :require_account
  before_action :connect_to_db
  after_action :cleanup_generic
  around_action :tag_current_account

  helper_method :current_account, :current_user, :admin?, :current_account?, :resource_for
  attr_accessor :current_collaborator

  def url_options
    { account_name: current_account&.name }.merge(super)
  end

  private

  def require_account
    session[:user] ||= 1 if Rails.env.development?
    redirect_to docs_url unless current_account
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
    current_account.present?
  end

  def current_account
    return @account if @account
    begin
      if session[:account]
        @account = Account.not_deleted.find session[:account]
      elsif current_user
        @account =
          if params[:account_name]
            current_user.enterprise_accounts.find_by name: params[:account_name]
          else
            current_user.enterprise_accounts.first
          end
        @current_collaborator = current_user.collaborators.find_by(account: @account)
      end
    rescue ActiveRecord::RecordNotFound
      session.delete :account
      nil
    end
  end

  def current_user
    @user ||= User.find session[:user] if session[:user]
  end

  def admin?
    (session[:account] && current_user.nil?) || current_collaborator&.is_administrator ||
      (current_user&.heroku_provider? && current_collaborator.nil?)
  end

  def require_admin
    redirect_to dashboard_url, flash: {error: 'You need administrator privileges to access this page.'} unless admin?
  end

  def table_not_found exception
    redirect_to dashboard_url,
      flash: { error: "The table <b>#{ERB::Util.h exception.table_name}</b> cannot be found." }
  end

  def cleanup_generic
    @generic&.cleanup
  end

  def global_db_error exception
    msg = "There was a database error, it might be a problem with your database URL.
      The error was : <pre>#{exception.message}</pre>"
    redirect_to edit_account_url, flash: { error: msg }
  end

  def statement_timeouts exception
    if exception.wrapped_exception.is_a?(PG::QueryCanceled) &&
       exception.wrapped_exception.message['statement timeout']
      @exception = exception
      render 'dashboards/statement_timeout'
    else
      raise exception
    end
  end

  def disconnect_on_exception exception
    @generic&.cleanup
    raise exception
  end

  def resource
    resource_for params[:id]
  end

  def resource_for table
    @resources ||= {}
    @resources[table.to_sym] ||= Resource.new @generic, table
  end

  def ensure_proper_subdomain
    if !Rails.env.production? || request.host_with_port['doctolib'] ||
       request.host_with_port['adminium-staging.herokuapp']
      return
    end
    redirect_to host: 'www.adminium.io' if request.host_with_port != 'www.adminium.io'
  end

  def heroku_api
    @api ||= PlatformAPI.connect_oauth(session[:heroku_access_token]) if session[:heroku_access_token]
  end

  def valid_db_url?
    current_account&.valid_db_url?
  end

  def tag_current_account
    logger.tagged("Account: #{session[:account] || 'No account'}|User: #{session[:user] || 'No user'}") {yield}
  end

  def check_permissions
    return if admin?
    @permissions = current_collaborator.permissions
    table = params[:table] || params[:id]
    return if user_can? action_name, table
    respond_to do |format|
      format.html do
        redirect_to dashboard_url, flash: {error: "You haven't the permission to perform #{action_name} on #{table}"}
      end
      format.js { head :forbidden }
    end
  end

  def user_can? action_name, table
    return false if action_name.to_s.in?(%w(create clone edit destroy)) && table.to_s == 'pg_stat_statements'
    return true if @permissions.nil?
    action_to_perm = {
      'index' => 'read', 'show' => 'read', 'search' => 'read', 'edit' => 'update', 'update' => 'update',
      'new' => 'create', 'create' => 'create', 'destroy' => 'delete', 'bulk_destroy' => 'delete', 'import' => 'create',
      'perform_import' => 'create', 'check_existence' => 'read', 'time_chart' => 'read', 'bulk_edit' => 'update',
      'bulk_update' => 'update', 'chart' => 'read'
    }
    @permissions[table.to_s] && @permissions[table.to_s][action_to_perm[action_name.to_s]]
  end
end
