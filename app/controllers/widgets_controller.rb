class WidgetsController < ApplicationController

  def create
    widget = current_account.widgets.create params[:widget]
    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.json do
        render nothing: true
      end
    end
  end

  def destroy
    current_account.widgets.destroy params[:id]
    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.js do
        render nothing: true
      end
    end
  end

  def update
    current_account.widgets.find(params[:id]).update_attributes params[:widget]
    render nothing: true
  end

end
