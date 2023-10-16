class DocsController < ApplicationController
  skip_before_action :require_user, :require_account, :connect_to_db

  def index
    @full_title = 'Documentation | Adminium'
  end

  def landing
    return redirect_to dashboard_url if session[:user_id]
    render layout: false
  end

  def keyboard_shortcuts
    render layout: false
  end
end
