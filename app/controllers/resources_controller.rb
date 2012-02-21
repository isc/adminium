class ResourcesController < ApplicationController
  
  before_filter :connect_to_db
  before_filter :fetch_item, :only => [:show, :edit, :update]
  
  def index
    @items = Generic.table(params[:table]).page(params[:page]).per(20)
    @items = @items.order(params[:order]) if params[:order].present?
  end
  
  def show
  end
  
  def edit
  end
  
  def update
    @item.update_attributes params
    redirect_to action:'show', id:@item.id, table:params[:table]
  end
  
  private
  def connect_to_db
    Generic.connect_and_domain_discovery "postgresql://ivan@localhost/dbinsights-demo"
  end
  
  def fetch_item
    @item = Generic.table(params[:table]).find params[:id]
  end
  
end
