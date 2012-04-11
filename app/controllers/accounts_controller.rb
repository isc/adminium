class AccountsController < ApplicationController
  
  before_filter :require_admin
  skip_filter :connect_to_db, :unless => :valid_db_url?
  
  def edit
    @account = current_account
  end
  
  def update
    if current_account.update_attributes params[:account]
      redirect_to edit_account_path, notice: 'Changes saved.'
    else
      render :edit
    end
  end
  
  private
  def valid_db_url?
    current_account.valid_db_url?
  end

end
