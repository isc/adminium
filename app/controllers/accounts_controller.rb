class AccountsController < ApplicationController

  before_filter :require_admin
  skip_filter :connect_to_db

  def edit
    @account = current_account
  end

  def update
    if current_account.update_attributes params[:account]
      if params[:install]
        redirect_to dashboard_path(:step=>'done')
      else
        redirect_to edit_account_path, notice: 'Changes saved.'
      end
    else
      render :edit
    end
  end

  private
  def valid_db_url?
    current_account.valid_db_url?
  end

end
