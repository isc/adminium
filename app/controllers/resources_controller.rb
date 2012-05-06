class ResourcesController < ApplicationController
  
  before_filter :table_access_limitation
  before_filter :check_permissions
  before_filter :apply_serialized_columns, only: [:index, :show]
  before_filter :apply_validations, only: [:create, :update, :new, :edit]
  before_filter :fetch_item, only: [:show, :edit, :update, :destroy]
  helper_method :clazz, :user_can?

  respond_to :json, :html, :xml, :csv, :only => :index

  def index
    @items = clazz.scoped #select(clazz.settings.columns[:listing].join(", "))
    #raise clazz.settings.filters.inspect
    @current_filter = clazz.settings.filters[params[:asearch]] || []
    @current_filter.each do |filter|
      @items = build_statement(@items, filter)
    end
    @items = @items.where(params[:where]) if params[:where].present?
    apply_search if params[:search].present?
    params[:order] ||= clazz.settings.default_order
    @items = @items.order(params[:order])
    respond_with(@items) do |format|
      format.html do
        check_per_page_setting
        @items = @items.page(params[:page]).per(clazz.settings.per_page)
      end
    end
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
      redirect_to resource_path(params[:table], @item), flash: {success: "#{object_name} successfully created."}
    else
      @form_url = resources_path(params[:table])
      render :new
    end
  end

  def update
    if @item.update_attributes item_params
      path = (params[:return_to] == "back") ? :back : resource_path(params[:table], @item)
      redirect_to path, flash: {success: "#{object_name} successfully updated."}
    else
      @form_url = resource_path(@item, table: params[:table])
      render :edit
    end
  end

  def destroy
    @item.destroy
    redirect_to :back, flash: {success: "#{object_name} successfully destroyed."}
  end

  def bulk_destroy
    clazz.destroy params[:item_ids]
    redirect_to :back, flash: {success: "#{params[:item_ids].size} #{class_name.pluralize} successfully destroyed."}
  end

  def bulk_edit

    @record_ids = params[:record_ids]

    if clazz.where({clazz.primary_key => params[:record_ids]}).count != @record_ids.length
      raise "BulkEditCheckRecordsFailed"
    end
    if @record_ids.length == 1
      @item = clazz.find(@record_ids.shift)
      @form_url = resource_path(@item, table: params[:table], return_to: :back)
    else
      @form_url = bulk_update_resources_path(params[:table])
      @item = clazz.new
    end
    render :layout => false
  end

  def bulk_update
    items = clazz.find(params[:record_ids]).map do |item|
      item.update_attributes!(item_params.reject{|k,v| v.blank?})
    end
    redirect_to :back, flash: {success: "#{items.length} rows has been updated"}
  end

  def test_threads
    Account.find_by_sql 'select pg_sleep(10)'
    render json: @generic.table('accounts').first.inspect
  end

  private

  def check_permissions
    return if admin?
    @permissions = current_collaborator.permissions
    unless user_can? action_name, params[:table]
      redirect_to dashboard_url, flash: {error: "You haven't the permission to perform #{action_name} on #{params[:table]}"}
    end
  end

  def user_can? action_name, table
    return true if @permissions.nil?
    action_to_perm = {'index' => 'read', 'show' => 'read', 'edit' => 'update', 'update' => 'update', 'new' => 'create', 'create' => 'create', 'destroy' => 'delete', 'bulk_destroy' => 'delete'}
    @permissions[table] && @permissions[table][action_to_perm[action_name]]
  end

  def fetch_item
    @item = clazz.find params[:id]
  end

  def check_per_page_setting
    per_page = params.delete(:per_page).to_i
    if per_page > 0 && clazz.settings.per_page != per_page
      clazz.settings.per_page = per_page
      clazz.settings.save
    end
  end

  def clazz
    @clazz ||= @generic.table(params[:table])
  end

  def item_params
    params[clazz.name.underscore.gsub('/', '_')]
  end

  def object_name
    "#{class_name} ##{@item[clazz.primary_key]}"
  end

  def class_name
    clazz.original_name.humanize
  end

  def apply_search
    columns = clazz.settings.columns[:search]
    query, datas = [], []
    columns.each do |column|
      if clazz.settings.is_number_column?(column)
        if params[:search].match(/\A\d+\Z/)
          query.push "#{column} = ?"
          datas.push params[:search].to_i
        end
      else
        query.push "upper(#{column}) like ?"
        datas.push "%#{params[:search]}%".upcase
      end
    end

    @items = @items.where([query.join(' OR '), datas].flatten)
  end

  def apply_serialized_columns
    clazz.settings.columns[:serialized].each do |column|
      clazz.serialize column
    end
  end

  def apply_validations
    clazz.settings.validations.each do |validation|
      clazz.send validation['validator'], validation['column_name']
    end
  end

  def build_statement scope, filter
    c = filter['column']
    params = nil
    unary_operator = UNARY_OPERATOR_DEFINITIONS[filter['operator']]
    if unary_operator
      return scope.where(unary_operator.gsub('_', c))
    end
    case filter['type']
      when 'integer'
        raise "Unsupported" unless INTEGER_OPERATORS.include?(filter['operator'])
        unless filter['operand'].blank?
          params = ["#{c} #{filter['operator']} ?", filter['operand']]
        end
      when 'string', 'text'
        operand = STRING_LIKE_OPERATOR_DEFINITIONS[filter['operator']]
        if operand
          like_operator = @generic.mysql? ? 'LIKE' : 'ILIKE'
          params = ["#{c} #{like_operator} ?", operand.gsub('_', filter['operand'])]
        end
        operand = STRING_OPERATOR_DEFINITIONS[filter['operator']]
        if operand
          params = operand.gsub('_', c)
        end
      when 'boolean'
        raise "Unsupported" unless BOOLEAN_OPERATORS.include?(filter['operator'])
        params = ["#{c} = ?", filter['operator'] == "is_true"]
      when 'datetime'
        raise "Unsupported #{filter['operator']}" unless DATETIME_OPERATORS.include?(filter['operator'])
        ranges = {'today' => [0, 'day'], 'yesterday' => [1, 'day'], 'this_week' => [0, 'week'], 'last_week' => [1, 'week']}
        range = ranges[filter['operator']]
        if range
          day = range.first.send(range.last).ago.to_date
          values = (range.last == 'week') ? [day.beginning_of_week, day.end_of_week] : [day, day]
          values = [values.first.beginning_of_day, values.last.end_of_day]
          params = ["#{c} BETWEEN ? AND ?", *values]
        end
        operators = {'after' => '>', 'before' => '<', 'on' => '='}
        if (operator = operators[filter['operator']]) && filter['operand'].match(/(\d{2}\/\d{2}\/\d{4})/)
          date = Date.strptime($1, '%m/%d/%Y')
          params = ["#{c} #{operator} ?", date]
        end
      else
        raise "Unsupported"
    end
    scope.where(params)
  end
  
  def table_access_limitation
    return unless current_account.pet_project?
    if (@generic.tables.index params[:table]) > 5
      redirect_to dashboard_url,
        notice: "You're currently on the free plan meant for pet projects which is limited to five tables of your schema.<br/>Upgrade to the startup plan to access your full schema with Adminium.".html_safe
    end
  end

end
