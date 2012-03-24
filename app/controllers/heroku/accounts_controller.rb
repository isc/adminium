class Heroku::AccountsController < ApplicationController
  
  skip_filter :connect_to_db, :require_authentication
  
  def update
    account = Account.find_by_api_key! params[:id]
    account.update_attributes params[:account]
    if account.valid_db_url?
      render text: 'OK'
    else
      render text: 'KO'
    end
  end
  
end
