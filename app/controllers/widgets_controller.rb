class WidgetsController < ApplicationController
  
  def create
    Widget.create! params[:widget].merge(account_id: current_account.id)
    redirect_to dashboard_url
  end
  
  def destroy
    current_account.widgets.destroy params[:id]
    render nothing: true
  end
  
end