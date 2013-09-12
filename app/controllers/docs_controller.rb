class DocsController < ApplicationController

  skip_filter :require_account
  skip_filter :connect_to_db, unless: :valid_db_url?

  def index
    @full_title = "Documentation | Adminium"
  end
  
  def install
    redirect_to "/auth/heroku"
  end
  
  def homepage
    redirect_to dashboard_url and return if session[:account]
    render layout: 'homepage'
  end
  
  def landing
    if session[:account]
      redirect_to dashboard_url
      return
    end
    if session[:user]
      redirect_to user_path
      return
    end
    render layout: false
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

end