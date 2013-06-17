class Heroku::ResourcesController < ApplicationController

  skip_filter :connect_to_db, :require_authentication, :ensure_proper_subdomain
  before_filter :basic_auth, except: :sso_login

  def create
    account = Account.create params[:resource].reject {|k,v| !%w(heroku_id plan callback_url).include?(k)}
    render json: { id: account.api_key, config: { 'ADMINIUM_URL' => heroku_account_url(account) } }
  end

  def destroy
    account = Account.find_by_api_key!(params[:id]).flag_as_deleted!
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
    app.update_column :name, params[:app] if app.name != params[:app]
    app.update_column :source, cookies[:source] if app.source.blank? && cookies[:source].present?
    session[:account] = app.id
    SignOn.create account_id: app.id, plan: app.plan,
      remote_ip: request.remote_ip, kind: SignOn::Kind::HEROKU
    redirect_to dashboard_url
  end

  private
  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      logger.warn "user #{user}, pass : #{pass}"
      user == HEROKU_MANIFEST['id'] && pass == HEROKU_MANIFEST['api']['password']
    end
  end

end
