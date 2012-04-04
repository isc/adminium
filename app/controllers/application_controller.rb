class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Generic::TableNotFoundException, with: :table_not_found
  before_filter :fixed_account
  before_filter :require_authentication
  before_filter :connect_to_db
  after_filter :cleanup_generic

  helper_method :global_settings, :current_account, :current_user

  private

  def fixed_account
    session[:account] = FIXED_ACCOUNT if session[:account].nil? && FIXED_ACCOUNT.present?
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

  def current_account
    @account ||= Account.find session[:account]
  end

  def current_user
    @user ||= User.find session[:user]
  end

  def table_not_found exception
    redirect_to edit_account_path, flash: {error: "The table <b>#{exception.table_name}</b> cannot be found.".html_safe}
  end

  def cleanup_generic
    @generic.try :cleanup
  end

end
