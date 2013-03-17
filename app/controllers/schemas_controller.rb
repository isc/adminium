class SchemasController < ApplicationController

  def show
    @title = 'Schema'
    params[:table] = params[:id]
    @indices = clazz.connection.indexes(params[:table])
  end

end