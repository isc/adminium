class Heroku::ResourcesController < ApplicationController

  skip_filter :connect_to_db
  before_filter :basic_auth, :except => :show
  
  def create
    account = Account.create params.reject {|k,v| ![:heroku_id, :plan, :callback_url].include?(k)}
    render :json => { :id => app.api_key, :config => { "ADMINIUM_URL" => admin_account_url(account) } }
  end
  
  def destroy
    Account.find_by_api_key!(params[:id]).destroy
    render :text => 'ok'
  end
  
  def update
    account = Account.find_by_api_key! params[:id]
    account.update_attribute :plan, params[:plan]
    render :text => 'ok'
  end
  
  def show
    token = "#{params[:id]}:nAHbKM0QP8eL8KIR:#{params[:timestamp]}"
    token = Digest::SHA1.hexdigest(token).to_s
    if token != params[:token] || (params[:timestamp].to_i < (Time.now - 2*60).to_i)
      render :text => 'bad token', :status => 403 and return
    end
    app = Account.find_by_api_key! params[:id]
    session[:user] = app.id
    cookies['heroku-nav-data'] = params['nav-data']
    redirect_to root_url
  end
  
  private
  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == HEROKU_API_USER && pass == HEROKU_API_PASS
    end
  end
  
end
