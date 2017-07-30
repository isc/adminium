class AccountsController < ApplicationController
  include AppInstall

  before_action :require_admin, except: :create
  skip_before_action :connect_to_db
  skip_before_action :require_account, only: :create

  def edit
    @active_pane = params[:pane] || 'database_connection'
    @account = current_account
    @heroku_collaborators = []
    @roles = @account.roles.order(:name).to_a if @account.enterprise?
    @account_collaborators = @account.collaborators.includes(:roles)
    if current_user&.heroku_provider?
      @heroku_collaborators = heroku_api.collaborator.list(current_account.name)
      real_heroku_collaborators = @account.collaborators.where(kind: 'heroku').pluck(:email)
      @heroku_collaborators.delete_if do |heroku_collaborator|
        real_heroku_collaborators.include? heroku_collaborator['user']['email']
      end
    end
  rescue Excon::Errors::Error
    @heroku_collaborators = []
  end

  def create
    heroku_api.addon.create(params[:name], plan: "adminium:#{params[:plan] || 'petproject'}")
    addon_id = heroku_api.addon.list.find {|addon| addon['app']['name'] == params[:name]}['id']
    @account = Account.where(deleted_at: nil).find_by heroku_uuid: addon_id
    session[:account] = @account.id
    current_account.name = params[:name]
    configure_db_url 'self-create'
    set_profile
    current_account.save!
    path = heroku_api.collaborator.list(current_account.name).size > 1 ? invite_team_install_path : dashboard_path
    render json: {success: true, redirect_path: path}
  rescue Excon::Errors::Error => e
    render json: {success: false, error: JSON.parse(e.response.body)['message']}
  end

  def upgrade
    if current_user&.heroku_provider?
      heroku_api.addon.update current_account.name, plan: "adminium:#{params[:plan]}"
      redirect_back fallback_location: dashboard_path
    else
      redirect_to 'https://addons.heroku.com/adminium'
    end
  rescue Excon::Errors::Error => error
    body = error.response.body
    @error = JSON.parse(body)['error'] rescue body
  end

  def update
    if params[:db_key] && session[:db_urls].present?
      db_url = session[:db_urls].detect {|url| url[:key] == params[:db_key]}
      params[:account] ||= {}
      params[:account][:db_url] = db_url[:value]
      params[:account][:db_url_setup_method] = current_account.db_url_setup_method.presence || 'oauth'
    else
      params[:account][:db_url_setup_method] = 'web'
    end
    if (current_account.id.to_s == ENV['DEMO_ACCOUNT_ID']) || current_account.update(account_params)
      if params[:install]
        redirect_to_invite_collaborators_or_dashboard
      else
        redirect_to edit_account_path, notice: 'Changes saved.'
      end
    else
      @heroku_collaborators = []
      render :edit
    end
  end

  def cancel_tips
    current_account.tips_opt_in = false
    render json: current_account.save
  end

  def db_url_presence
    render json: current_account.db_url?
  end

  def redirect_to_invite_collaborators_or_dashboard
    path = if current_user&.heroku_provider? && heroku_api.collaborator.list(current_account.name).many?
             invite_team_install_path
           else
             dashboard_path
           end
    redirect_to path
  rescue Excon::Errors::Error
    redirect_to dashboard_path
  end

  private

  def account_params
    params.require(:account).permit(:db_url, :db_url_setup_method, :application_time_zone, :database_time_zone)
  end
end
