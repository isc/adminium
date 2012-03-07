class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :fixed_account
  before_filter :fetch_account
  before_filter :connect_to_db

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
        begin
          @generic = Generic.new @account
          @tables = @generic.tables
        rescue
          p $!
        end
      else
        redirect_to doc_url(:missing_db_url)
      end
    else
      redirect_to docs_url
    end
  end

end
