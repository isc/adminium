class ResourcesController < ApplicationController

  before_filter :fetch_item, :only => [:show, :edit, :update]
  helper_method :clazz

  def index
    @items = clazz.select(clazz.settings.column_names.join(", ")).page(params[:page]).per(clazz.settings.per_page)
    @items = @items.order(params[:order]) if params[:order].present?
  end

  def show
  end

  def edit
  end
  
  def new
    @item = clazz.new
  end
  
  def create
    @item = clazz.new params[@item.class.name.downcase]
    if @item.save
      redirect_to resource_path(params[:table], @item.id), :success => 'So cool'
    else
      render :new
    end
  end

  def update
    @item.update_attributes params[@item.class.name.downcase]
    redirect_to action:'show', id:@item.id, table:params[:table]
  end

  private

  def fetch_item
    @item = clazz.find params[:id]
  end

  def clazz
    @clazz ||= Generic.table(params[:table])
  end

end
