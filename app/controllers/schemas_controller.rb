class SchemasController < ApplicationController


  def show
    params[:table] = params[:id]
  end

end