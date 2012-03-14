class DocsController < ApplicationController
  
  skip_filter :require_authentication
  skip_filter :connect_to_db
  
  def index
  end
  
  def show
    render params[:id]
  end
  
end