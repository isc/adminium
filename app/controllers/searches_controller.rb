class SearchesController < ApplicationController
  def update
    search = searches.find_or_initialize_by params.permit(:name)
    search.conditions = params[:filters].values
    search.save!
    redirect_to resources_path(params[:id], asearch: params[:name])
  end

  def destroy
    searches.find_by(params.permit(:name)).destroy
    redirect_to resources_path(params[:id])
  end

  def show
    render json: searches.pluck(:name)
  end

  private
  def searches
    current_account.searches.where(table: params[:id])
  end
end
