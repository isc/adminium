class Heroku::ResourcesController < ApplicationController

  skip_filter :connect_to_db, :require_authentication
  before_filter :basic_auth, except: :sso_login
  
  def create
    Rails.logger.warn "Params on heroku create : #{params.inspect}"
    account = Account.create params[:resource].reject {|k,v| ![:heroku_id, :plan, :callback_url].include?(k)}
    render json: { id: account.api_key, config: { 'ADMINIUM_URL' => heroku_account_url(account) } }
  end
  
  def destroy
    Account.find_by_api_key!(params[:id]).destroy
    render text: 'ok'
  end
  
  def update
    account = Account.find_by_api_key! params[:id]
    account.update_attribute :plan, params[:plan]
    render text: 'ok'
  end
  
  def sso_login
    token = "#{params[:id]}:#{HEROKU_MANIFEST['api']['sso_salt']}:#{params[:timestamp]}"
    token = Digest::SHA1.hexdigest(token).to_s
    if token != params[:token] || (params[:timestamp].to_i < (Time.now - 2*60).to_i)
      render text: 'bad token', status: 403 and return
    end
    app = Account.find_by_api_key! params[:id]
    session[:account] = app.id
    cookies['heroku-nav-data'] = params['nav-data']
    redirect_to root_url
  end
  
  private
  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      logger.warn "user #{user}, pass : #{pass}"
      user == HEROKU_MANIFEST['id'] && pass == HEROKU_MANIFEST['api']['password']
    end
  end
  
end
