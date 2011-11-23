class QueriesController < ApplicationController
  
  def long
    Widget.find_by_sql("select pg_sleep(#{params[:id]})")
    render :text => 'yay'
  end
  
end
