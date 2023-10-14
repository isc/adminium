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

  def letsencrypt
    render text: 'fnq-Kc7y8c_OqxtwqpZvfngihGJ5a8wD0gaqxvXfQRo.yKKMdNQFLakFntj87ohHtFUO8u4tojwzKXkzEjD8RpE'
  end
end
