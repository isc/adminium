class WidgetsController < ApplicationController

  def create
    current_account.widgets.create params[:widget]
    redirect_to dashboard_url
  end

  def destroy
    current_account.widgets.destroy params[:id]
    render nothing: true
  end

  def update
    current_account.widgets.find(params[:id]).update_attributes params[:widget]
    render nothing: true
  end

end
