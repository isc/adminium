class Heroku::AccountsController < ApplicationController  
  skip_before_action :connect_to_db, :require_account, :ensure_proper_subdomain

  def update
    account = Account.find_by! api_key: params[:id]
    params[:account][:db_url_setup_method] = 'cli'
    account.update params[:account]
    if account.valid_db_url?
      render plain: 'OK'
    else
      render plain: 'KO'
    end
  end
end
