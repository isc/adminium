class Heroku::ResourcesController < ApplicationController
  skip_before_action :connect_to_db, :require_account, :verify_authenticity_token
  before_action :basic_auth, except: :sso_login

  def create
    attributes = params.require(:resource).permit :plan, :callback_url
    attributes[:heroku_id] = attributes[:callback_url].strip.split('/').last
    account = Account.deleted.find_by heroku_id: attributes[:heroku_id]
    if account
      account.reactivate attributes
    else
      account = Account.create attributes
    end
    render json: { id: account.api_key, config: { 'ADMINIUM_URL' => heroku_account_url(account) } }
  end

  def destroy
    Account.find_by!(api_key: params[:id]).flag_as_deleted!
    render plain: 'ok'
  end

  def update
    account = Account.find_by! api_key: params[:id]
    account.update! plan: params.require(:plan)
    render plain: 'ok'
  end

  def sso_login
    token = "#{params[:id]}:#{HEROKU_MANIFEST['api']['sso_salt']}:#{params[:timestamp]}"
    token = Digest::SHA1.hexdigest(token).to_s
    if token != params[:token] || (params[:timestamp].to_i < (Time.now.utc - 2 * 60).to_i)
      return render plain: 'bad token', status: 403
    end
    app = Account.find_by! api_key: params[:id]
    app.update_column :name, params[:app] if app.name != params[:app]
    app.update_column :source, cookies[:source] if app.source.blank? && cookies[:source].present?
    session[:account] = app.id
    SignOn.create account_id: app.id, plan: app.plan, remote_ip: request.remote_ip, kind: SignOn::Kind::HEROKU
    redirect_to dashboard_url
  end

  private

  def basic_auth
    authenticate_or_request_with_http_basic do |user, pass|
      user == HEROKU_MANIFEST['id'] && pass == HEROKU_MANIFEST['api']['password']
    end
  end
end
