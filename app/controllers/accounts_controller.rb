class AccountsController < ApplicationController
  
  skip_filter :connect_to_db
  
  def edit
    @account = current_account
  end
  
  def update
    if current_account.update_attributes params[:account]
      redirect_to edit_account_path, :notice => 'Changes saved.'
    else
      render :edit
    end
  end

end
