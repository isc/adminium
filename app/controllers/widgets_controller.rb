class WidgetsController < ApplicationController

  def create
    Widget.create! params[:widget].merge(account_id: current_account.id)
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