class SchemasController < ApplicationController

  def show
    @title = 'Schema'
    params[:table] = params[:id]
    @resource = resource_for params[:table]
  end

end