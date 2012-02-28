class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :fixed_account
  before_filter :connect_to_db
  
  private
  
  def fixed_account
    session[:user] = FIXED_ACCOUNT if session[:user].nil? && FIXED_ACCOUNT.present?
  end
  
  def connect_to_db
    if session[:user]
      account = Account.find session[:user]
      if account.db_url.present?
        begin
          Generic.connect_and_domain_discovery account
          @tables = Generic.tables
        rescue
          p $!
        end
      else
        redirect_to doc_url(:id => 'missing_db_url')
      end
    else
      redirect_to docs_url
    end
  end
  
end
