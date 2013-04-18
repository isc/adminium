class SearchesController < ApplicationController

  def update
    if params[:name] && params[:filters]
      resource.filters[params[:name]] = params[:filters].values
      resource.save
    end
    redirect_to resources_path(params[:id], asearch: params[:name])
  end

  def destroy
    settings = @generic.table(params[:id]).settings
    settings.filters.delete params[:name]
    settings.save
    redirect_to resources_path(params[:id])
  end

  def show
    render json: @generic.table(params[:id]).settings.filters.keys
  end

end
