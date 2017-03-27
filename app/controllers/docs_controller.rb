class DocsController < ApplicationController
  skip_before_action :require_account
  skip_before_action :connect_to_db

  def index
    @full_title = 'Documentation | Adminium'
  end

  def install
    redirect_to '/auth/heroku'
  end

  def landing
    return redirect_to dashboard_url if session[:account]
    return redirect_to user_path if session[:user]
    render layout: false
  end

  def keyboard_shortcuts
    render layout: false
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

  def letsencrypt
    render text: 'OURMkg6u4YIwv0lHBJIQGyPRaUDhKTET5b_ZQwD70do.yKKMdNQFLakFntj87ohHtFUO8u4tojwzKXkzEjD8RpE'
  end
end
