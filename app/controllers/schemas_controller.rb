class SchemasController < ApplicationController


  def show
    @title = 'Schema'
    params[:table] = params[:id]
  end

end