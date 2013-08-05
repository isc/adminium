class Heroku::AccountsController < ApplicationController
  
  skip_filter :connect_to_db, :require_account, :ensure_proper_subdomain
  
  def update
    account = Account.find_by_api_key! params[:id]
    params[:account][:db_url_setup_method] = 'cli'
    account.update_attributes params[:account]
    if account.valid_db_url?
      render text: 'OK'
    else
      render text: 'KO'
    end
  end
  
end
