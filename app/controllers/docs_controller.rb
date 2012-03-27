class DocsController < ApplicationController
  
  skip_filter :require_authentication
  skip_filter :connect_to_db, :unless => :valid_db_url?
  
  def index
  end
  
  def show
    render params[:id]
  end
  
  private
  def valid_db_url?
    session[:account] && current_account.valid_db_url?
  end
  
end