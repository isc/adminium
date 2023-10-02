class AccountsController < ApplicationController
  include AppInstall

  before_action :require_admin
  skip_before_action :connect_to_db

  def edit; end

  def update
    if params[:db_key] && session[:db_urls].present?
      db_url = session[:db_urls].detect { |url| url['key'] == params[:db_key] }
      params[:account] ||= {}
      params[:account][:db_url] = db_url['value']
      params[:account][:db_url_setup_method] = current_account.db_url_setup_method.presence || 'oauth'
      session.delete :db_urls
    else
      params[:account][:db_url_setup_method] = 'web'
    end
    if (current_account.id.to_s == ENV['DEMO_ACCOUNT_ID']) || current_account.update(account_params)
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
      .permit(:db_url, :db_url_setup_method, :application_time_zone, :database_time_zone,
        :per_page, :date_format, :datetime_format)
  end
end
