class AccountsController < ApplicationController
  
  include AppInstall

  before_filter :require_admin, except: :create
  skip_filter :connect_to_db
  skip_filter :require_account, only: :create

  def edit
    @account = current_account
    @heroku_collaborators = []
    if current_user.try(:heroku_provider?)
      @heroku_collaborators = heroku_api.get_collaborators(current_account.name).data[:body]
      real_heroku_collaborators = @account.collaborators.where(kind: 'heroku').map &:email
      @heroku_collaborators.delete_if {|heroku_collaborator| real_heroku_collaborators.include? heroku_collaborator['email']}
    end
  rescue Heroku::API::Errors::ErrorWithResponse => e
    @heroku_collaborators = []
  end
  
  def create
    app_name = params[:name]
    app_id = params[:app_id]
    resp = heroku_api.post_addon(app_name, "adminium:#{params[:plan]}" || 'petproject')
    if resp.data[:body]["status"] == "Installed"
      @account = Account.find_by_heroku_id "app#{app_id}@heroku.com"
      session[:account] = @account.id
      current_account.name = app_name
      configure_db_url('self-create')
      set_profile
      set_collaborators
      current_account.save!
      path = current_account.total_heroku_collaborators > 1 ? invite_team_install_path : dashboard_path
      render json: {success: true, redirect_path: path}
    else
      render json: {success: false, error: resp.data[:body]["status"]}
    end
  rescue Heroku::API::Errors::ErrorWithResponse => e
    render json: {sucess: false, error: JSON.parse(e.response.data[:body])["error"]}
  end
  
  def upgrade
    if current_user.try(:heroku_provider?)
      heroku_api.put_addon(current_account.name, "adminium:#{params[:plan]}")
      redirect_to :back
    else
      redirect_to "https://addons.heroku.com/adminium"
    end
  rescue Heroku::API::Errors::ErrorWithResponse => e
    @error = e
  end
  
  def update
    if params[:db_key] && session[:db_urls].present?
      db_url = session[:db_urls].detect{|db_url| db_url[:key] == params[:db_key]}
      params[:account] ||= {}
      params[:account][:db_url] = db_url[:value]
      session[:db_urls]
      params[:account][:db_url_setup_method] = current_account.db_url_setup_method.presence || 'oauth'
    else
      params[:account][:db_url_setup_method] = 'web'
    end
    if (current_account.id.to_s == ENV['DEMO_ACCOUNT_ID']) || current_account.update_attributes(params[:account])
      if params[:install]
        redirect_to_invite_collaborators_or_dashbord
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
    res = current_account.save
    render json: res
  end

  def db_url_presence
    render json: current_account.db_url.present?
  end
  
  def redirect_to_invite_collaborators_or_dashbord
    path = if current_user.try(:heroku_provider?) && heroku_api.get_collaborators(current_account.name).data[:body].length > 1
      invite_team_install_path
    else
      dashboard_path
    end
    redirect_to path
  rescue Heroku::API::Errors::ErrorWithResponse => e
    redirect_to dashboard_path
  end

end
