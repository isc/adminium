class DocsController < ApplicationController

  skip_filter :require_authentication
  skip_filter :connect_to_db, unless: :valid_db_url?

  def index
    @full_title = "Documentation | Adminium"
  end

  def homepage
    redirect_to dashboard_url and return if session[:account]
    render layout: 'homepage'
  end

  def show
    options = {}
    options[:layout] = false if params[:no_layout]
    render params[:id], options
  end

  def start_demo
    session[:account_before_demo] = session[:account] unless session[:account] == ENV['DEMO_ACCOUNT_ID']
    session[:account] = ENV['DEMO_ACCOUNT_ID']
    redirect_to dashboard_url
  end

  def stop_demo
    session[:account] = session[:account_before_demo]
    redirect_to dashboard_url
  end

  private
  def valid_db_url?
    session[:account] && current_account.valid_db_url?
  end

end