class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Exception, with: :disconnect_on_exception
  rescue_from Generic::TableNotFoundException, with: :table_not_found
  rescue_from Sequel::DatabaseError, with: :statement_timeouts
  rescue_from Sequel::DatabaseConnectionError, with: :global_db_error
  before_action :require_user
  before_action :require_account
  before_action :connect_to_db
  after_action :cleanup_generic
  around_action :tag_current_account

  helper_method :current_account, :current_user, :admin?, :current_account?, :resource_for
  add_flash_types :success, :error

  private

  def require_user
    redirect_to new_session_path unless current_user
  end

  def require_account
    return redirect_to new_account_path if Account.none?
  end

  def connect_to_db
    return unless current_account
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
    @account ||= Account.find session[:account] if session[:account]
  rescue ActiveRecord::RecordNotFound
    session.delete :account
    nil
  end

  def current_user
    @user ||= User.find session[:user_id] if session[:user_id]
  end

  def current_collaborator
    return nil unless session[:collaborator]
    @collaborator ||= Collaborator.find_by(id: session[:collaborator])
    return @collaborator if @collaborator
    session[:collaborator] = session[:account] = nil
  end

  def admin?
    current_collaborator&.is_administrator
  end

  def require_admin
    redirect_to dashboard_url, error: 'You need administrator privileges to access this page.' unless admin? || Account.none?
  end

  def table_not_found exception
    redirect_to dashboard_url, error: "The table <b>#{ERB::Util.h exception.table_name}</b> cannot be found."
  end

  def cleanup_generic
    @generic&.cleanup
  end

  def global_db_error exception
    msg = "There was a database error, it might be a problem with your database URL.
      The error was : <pre>#{exception.message}</pre>"
    redirect_to edit_account_url, error: msg
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

  def valid_db_url?
    current_account&.valid_db_url?
  end

  def tag_current_account
    logger.tagged("Account: #{session[:account] || 'No account'}|User: #{session[:user_id] || 'No user'}") {yield}
  end

  def check_permissions
    return if admin?
    @permissions = current_collaborator.permissions
    table = params[:table] || params[:id]
    return if user_can? action_name, table
    respond_to do |format|
      format.html do
        redirect_to dashboard_url, error: "You haven't the permission to perform #{action_name} on #{table}"
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

  def table_configuration_for table
    current_account.table_configuration_for table
  end

  def relying_party
    @relying_party ||=
      WebAuthn::RelyingParty.new(origin: ENV['WEBAUTHN_ORIGIN'] || 'http://localhost:3000', name: 'Adminium')
  end
end
