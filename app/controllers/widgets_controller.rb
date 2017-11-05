class WidgetsController < ApplicationController
  def create
    current_account.widgets.create! widget_params
    respond_to do |format|
      format.html do
        redirect_back fallback_location: dashboard_path
      end
      format.json do
        head :no_content
      end
    end
  end

  def destroy
    current_account.widgets.destroy params[:id]
    respond_to do |format|
      format.html do
        redirect_back fallback_location: dashboard_path
      end
      format.js do
        head :no_content
      end
    end
  end

  def update
    current_account.widgets.find(params[:id]).update! widget_params
    head :no_content
  end

  private

  def widget_params
    params.require(:widget).permit(:table, :advanced_search, :order, :type, :columns, :grouping)
  end
end
