class AccountsController < ApplicationController
  
  skip_filter :connect_to_db
  before_filter :check_logged_in
  
  def edit
  end
  
  def update
    if @account.update_attributes params[:account]
      redirect_to edit_account_path, :notice => 'Changes saved.'
    else
      render :edit
    end
  end
  
  private
  def check_logged_in
    if session[:user]
      @account = Account.find session[:user]
    else
      redirect_to docs_url
    end
  end
  
end