class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from Generic::TableNotFoundException, :with => :table_not_found
  before_filter :fixed_account
  before_filter :fetch_account
  before_filter :connect_to_db
  after_filter :cleanup_generic

  helper_method :global_settings

  private

  def fixed_account
    session[:user] = FIXED_ACCOUNT if session[:user].nil? && FIXED_ACCOUNT.present?
  end

  def global_settings
    @global_settings ||= Settings::Global.new(session[:user])
  end

  def fetch_account
    @account = Account.find session[:user] if session[:user]
  end

  def connect_to_db
    if @account
      if @account.db_url.present?
        @generic = Generic.new @account
        @tables = @generic.tables
      else
        redirect_to doc_url(:missing_db_url)
      end
    else
      redirect_to docs_url
    end
  end
  
  def table_not_found exception
    redirect_to edit_account_path, :flash => {:error => "The table <b>#{exception.table_name}</b> cannot be found.".html_safe}
  end
  
  def cleanup_generic
    @generic.try :cleanup
  end

end
