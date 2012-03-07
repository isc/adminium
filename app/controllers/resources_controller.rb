class ResourcesController < ApplicationController

  before_filter :fetch_item, :only => [:show, :edit, :update, :destroy]
  helper_method :clazz

  def index
    @items = clazz.select(clazz.settings.columns[:listing].join(", "))
    clazz.settings.filters.each do |filter|
      @items = build_statement(@items, filter)
    end
    @items = @items.page(params[:page]).per(clazz.settings.per_page)
    @items = @items.where(params[:where]) if params[:where]
    @items = @items.order(params[:order].present? ? params[:order] : clazz.settings.default_order)
  end

  def show
  end

  def edit
    @form_url = resource_path(@item, table: params[:table])
  end

  def new
    @form_url = resources_path(params[:table])
    @item = clazz.new
  end

  def create
    @item = clazz.new item_params
    if @item.save
      redirect_to resource_path(params[:table], @item.id), :flash => {:success => "#{object_name} successfully created."}
    else
      render :new
    end
  end

  def update
    @item.update_attributes item_params
    redirect_to resource_path(params[:table], @item.id), :flash => {:success => "#{object_name} successfully updated."}
  end

  def destroy
    @item.destroy
    redirect_to resources_path, :flash => {:success => "#{object_name} successfully destroyed."}
  end

  private

  def fetch_item
    @item = clazz.find params[:id]
  end

  def clazz
    @clazz ||= @generic.table(params[:table])
  end

  def item_params
    params[@clazz.name.underscore.gsub('/', '_')]
  end

  def object_name
    "#{@clazz.original_name.humanize} ##{@item.id}"
  end

  def build_statement scope, filter
    c = filter['column']
    params = nil
    unary_operators = {'blank' => "_ IS NULL OR _ = ''", 'present' => "_ IS NOT NULL AND _ != ''"}
    unary_operator = unary_operators[filter['operator']]
    if unary_operator
      return scope.where(unary_operator.gsub('_', filter['column']))
    end
    case filter['type']
      when 'integer'
        raise "Unsupported" unless INTEGER_OPERATORS.include?(filter['operator'])
        params = ["#{c} #{filter['operator']} ?", filter['operand']]
      when 'string'
        string_operators = {'like' => '%_%', 'starts_with' => '_%', 'ends_with' => '%_', 'is' => '_'}
        value = string_operators[filter['operator']].gsub('_', filter['operand'])
        like_operator = 'ILIKE'
        params = ["#{c} #{like_operator} ?", value]
      when 'datetime'
        raise "Unsupported #{filter['operator']}" unless DATETIME_OPERATORS.include?(filter['operator'])
        ranges = {'today' => [0, 'day'], 'yesterday' => [1, 'day'], 'this_week' => [0, 'week'], 'last_week' => [1, 'week']}
        range = ranges[filter['operator']]
        if range
          day = range.first.send(range.last).ago.to_date
          values = (range.last == 'week') ? [day.beginning_of_week, day.end_of_week] : [day, day]
          values = [values.first.beginning_of_day, values.last.end_of_day]
          ["#{c} BETWEEN ? AND ?", values]
        end
        operators = {'before' => '>', 'after' => '<'}
        if operator = operators[filter['operator']]
          date = Date.strptime(filter['operand'].match(/([0-9]{8})/)[1], '%m%d%Y')
          ["#{c} #{operator} #{date}"]
        end
      else
        raise "Unsupported"
    end
    scope.where(params)
  end

end
