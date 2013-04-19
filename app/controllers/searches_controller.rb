class SearchesController < ApplicationController

  def update
    if params[:name] && params[:filters]
      resource.filters[params[:name]] = params[:filters].values
      resource.save
    end
    redirect_to resources_path(params[:id], asearch: params[:name])
  end

  def destroy
    resource.filters.delete params[:name]
    resource.save
    redirect_to resources_path(params[:id])
  end

  def show
    render json: @generic.table(params[:id]).settings.filters.keys
  end

end
