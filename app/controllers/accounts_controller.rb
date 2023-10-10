class AccountsController < ApplicationController
  before_action :require_admin
  skip_before_action :connect_to_db, :require_account

  def new; end

  def create
    account = Account.create! params.require(:account).permit(:name)
    collaborator = current_user.collaborators.create! account: account,
      user: current_user, is_administrator: true, email: current_user.email
    session[:account] = account.id
    session[:collaborator] = collaborator.id
    redirect_to dashboard_path
  end

  def edit; end

  def update
    if current_account.update(account_params)
      if params[:install]
        redirect_to dashboard_path
      else
        redirect_to edit_account_path, notice: 'Changes saved.'
      end
    else
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

  private

  def account_params
    params.require(:account)
      .permit(:db_url, :application_time_zone, :database_time_zone, :per_page, :date_format, :datetime_format)
  end
end
