class SchemasController < ApplicationController

  def show
    @title = 'Schema'
    params[:table] = params[:id]
    @resource = Resource::Base.new @generic, params[:table]
  end

end