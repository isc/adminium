class AccountsController < ApplicationController

  before_filter :require_admin
  skip_filter :connect_to_db
  skip_filter :ensure_proper_subdomain, only: 'update'

  def edit
    @account = current_account
  end

  def update
    if current_account.update_attributes params[:account]
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
    res = current_account.save
    render json: res
  end

  def db_url_presence
    render json: current_account.db_url.present?
  end

end
