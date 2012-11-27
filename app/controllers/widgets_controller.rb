class WidgetsController < ApplicationController

  respond_to :json, :html, only: [:create]

  def create
    widget = current_account.widgets.create params[:widget]
    respond_with widget do |format|
      format.html do
        redirect_to dashboard_url
      end
      format.json do
        render nothing: true
      end
    end
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
