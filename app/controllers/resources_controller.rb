require "activerecord-import/base"

class ResourcesController < ApplicationController

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper
  include ResourcesHelper

  before_filter :table_access_limitation
  before_filter :check_permissions
  before_filter :apply_serialized_columns, only: [:index, :show]
  before_filter :apply_validations, only: [:create, :update, :new, :edit]
  before_filter :fetch_item, only: [:show, :edit, :update, :destroy]
  helper_method :clazz, :user_can?

  respond_to :json, :html, only: [:index, :update]
  respond_to :json, only: [:perform_import]
  respond_to :csv, only: :index

  def index
    @items = clazz.select("#{quoted_table_name}.*")
    @current_filter = clazz.settings.filters[params[:asearch]] || []
    @widget = current_account.widgets.where(table: params[:table], advanced_search: params[:asearch]).first
    @current_filter.each do |filter|
      @items = build_statement(@items, filter)
    end
    @items = @items.where(params[:where]) if params[:where].present?
    apply_includes
    apply_has_many_counts
    apply_search if params[:search].present?
    apply_order
    update_export_settings
    respond_with @items do |format|
      format.html do
        check_per_page_setting
        @items = @items.page(params[:page]).per(clazz.settings.per_page)
      end
      format.json do
        @items = @items.page(1).per(10)
        render json: {
          widget: render_to_string(partial: 'items', locals: {items: @items.to_a, actions_cell: false}),
          id: params[:widget_id],
          total_count: @items.total_count
        }
      end
      format.csv do
        send_data generate_csv, type: 'text/csv'
      end
    end
  end

  def show
  end

  def edit
    @form_url = resource_path(@item, table: params[:table])
  end

  def import
  end

  def perform_import
    columns = params[:headers]
    values = params[:rows].values
    pkey = clazz.primary_key.to_sym
    fromId = clazz.last.try pkey || 0
    ActiveRecord::Import.require_adapter('postgresql')
    begin
      clazz.import columns, values, :validate => false
    rescue => error
      result = {error: error.to_s}
    end
    toId = clazz.last.try pkey || 0
    if (fromId == toId)
      result = {error: 'no new record were imported'}
    else
      import_filter = [{"column"=>pkey, "type"=>"integer", "operator"=>">", "operand"=>fromId}, {"column"=>pkey, "type"=>"integer", "operator"=>"<=", "operand"=>toId}]
      clazz.settings.filters['last_import'] =  import_filter
      clazz.settings.save
      result = {success: true}
    end
    render json: result.to_json
  end

  def new
    @form_url = resources_path(params[:table])
    @item = clazz.new
  end

  def create
    @item = clazz.new item_params
    if @item.save
      redirect_to after_save_redirection, flash: {success: "#{object_name} successfully created."}
    else
      @form_url = resources_path params[:table]
      render :new
    end
  rescue ActiveRecord::StatementInvalid => e
    flash.now[:error] = e.message
    @form_url = resources_path params[:table]
    render :new
  end

  def update
    if @item.update_attributes item_params
      respond_with(@item) do |format|
        format.html do
          redirect_to after_save_redirection, flash: {success: "#{object_name} successfully updated."}
        end
        format.json do
          column_name = item_params.keys.first
          value = display_attribute :td, @item, column_name
          render json: {result: :success, value: value, column: column_name, id: @item[clazz.primary_key]}
        end
      end
    else
      respond_with(@item) do |format|
        format.html do
          @form_url = resource_path(@item, table: params[:table])
          render :edit
        end
        format.json do
          column_name = item_params.keys.first
          render json: {result: :failed, message: @item.errors.full_messages, column: column_name, id: @item[clazz.primary_key]}
        end
      end
    end
  rescue ActiveRecord::StatementInvalid => e
    respond_with @item do |format|
      format.html {redirect_to :back, flash: {error: e.message}}
      format.json do
        column_name = item_params.keys.first
        render json: {result: :failed, message: e.message, column: column_name, id: @item[clazz.primary_key]}
      end
    end
  end

  def destroy
    @item.destroy
    redirection = params[:redirect] == 'index' ? resources_path(params[:table]) : :back
    redirect_to redirection, flash: {success: "#{object_name} successfully destroyed."}
  rescue ActiveRecord::StatementInvalid => e
    redirect_to :back, flash: {error: e.message}
  end

  def bulk_destroy
    params[:item_ids].map! {|id| id.split(',')} if clazz.primary_key.is_a?(Array)
    clazz.destroy params[:item_ids]
    redirect_to :back, flash: {success: "#{params[:item_ids].size} #{class_name.pluralize} successfully destroyed."}
  rescue ActiveRecord::StatementInvalid => e
    redirect_to :back, flash: {error: e.message}
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
      @item = blank_object clazz.new
    end
    render layout: false
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

  def update_export_settings
    if params[:export_columns].present?
      clazz.settings.columns[:export] = params[:export_columns].delete_if {|e|e.empty?}
      clazz.settings.csv_options = params[:csv_options]
      clazz.settings.save
    end
  end

  def check_permissions
    return if admin?
    @permissions = current_collaborator.permissions
    unless user_can? action_name, params[:table]
      redirect_to dashboard_url, flash: {error: "You haven't the permission to perform #{action_name} on #{params[:table]}"}
    end
  end

  def user_can? action_name, table
    return true if @permissions.nil?
    action_to_perm = {'index' => 'read', 'show' => 'read', 'edit' => 'update', 'update' => 'update', 'new' => 'create', 'create' => 'create', 'destroy' => 'delete', 'bulk_destroy' => 'delete', 'import' => 'create', 'perform_import' => 'create'}
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
    clazz.original_name.underscore.humanize
  end

  def apply_search
    columns = clazz.settings.columns[:search]
    query, datas = [], []
    columns.each do |column|
      quoted_column = quote_column_name column
      if clazz.settings.is_number_column?(column)
        if params[:search].match(/\A\-?\d+\Z/)
          query.push "#{quoted_table_name}.#{quoted_column} = ?"
          datas.push params[:search].to_i
        end
      elsif clazz.settings.is_text_column?(column)
        query.push "upper(#{quoted_table_name}.#{quoted_column}) like ?"
        datas.push "%#{params[:search]}%".upcase
      end
    end
    @items = @items.where([query.join(' OR '), datas].flatten)
  end

  def apply_includes
    assocs = clazz.settings.columns[settings_type].find_all {|c| c.include?('.')}.map {|c| c.split('.').first}
    assocs += clazz.settings.columns[settings_type].map {|c| clazz.foreign_key?(c)}.compact
    assocs.each do |assoc|
      next if !assoc.is_a?(String) && assoc.options[:polymorphic]
      @items = @items.includes(assoc.is_a?(String) ? "_adminium_#{assoc}".to_sym : assoc.name)
    end
  end

  def apply_has_many_counts
    clazz.settings.columns[settings_type].find_all {|c| c.starts_with? 'has_many/'}.each do |column|
      assoc = column.gsub('has_many/', '')
      _, reflection = clazz.reflections.detect {|m, r| r.original_name == assoc}
      next if reflection.nil?
      grouping_column = "#{quoted_table_name}.#{quote_column_name clazz.primary_key}"
      count_on = "#{quote_table_name assoc}.#{quote_column_name @generic.table(assoc).primary_key}"
      outer_join = "#{quote_table_name assoc}.#{quote_column_name reflection.foreign_key} = #{grouping_column}"
      @items = @items.joins("left outer join #{assoc} on #{outer_join}").select("count(distinct #{count_on}) as #{quote_column_name column}")
      @items = @items.group(grouping_column) unless @items.group_values.include? grouping_column
    end
  end

  def apply_order
    params[:order] ||= clazz.settings.default_order
    # FIXME Not that clean. Removing quotes is for has_many/things sorting (not quoted in settings.columns)
    # order_column = params[:order].gsub(/ (desc|asc)/, '').gsub('"', '')
    # if order_column.include? '.'
    #   order_column = "#{order_column.split('.').first.singularize}.#{order_column.split('.').last}"
    # end
    # params[:order] = clazz.primary_key unless clazz.settings.columns[settings_type].include? order_column
    params[:order] = "#{quoted_table_name}.#{params[:order]}" unless params[:order][/[.\/]/]
    @items = @items.order(params[:order])
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
    if clazz.primary_keys.present?
      clazz.primary_keys.each do |primary_key|
        clazz.send :validates_presence_of, primary_key
      end
    end
  end

  def build_statement scope, filter
    c = "#{quoted_table_name}.#{quote_column_name filter['column']}"
    params = nil
    unary_operator = UNARY_OPERATOR_DEFINITIONS[filter['operator']]
    if unary_operator
      return scope.where(unary_operator.gsub('_', c))
    end
    case filter['type']
      when 'integer', 'float', 'decimal'
        raise "Unsupported" unless INTEGER_OPERATORS.include?(filter['operator'])
        params = ["#{c} #{filter['operator']} ?", filter['operand']] unless filter['operand'].blank?
      when 'string', 'text'
        operand = STRING_LIKE_OPERATOR_DEFINITIONS[filter['operator']]
        if operand
          like_operator = @generic.mysql? ? 'LIKE' : 'ILIKE'
          params = ["#{c} #{like_operator} ?", operand.gsub('_', filter['operand'])]
        end
        params = ["#{c} != ?", filter['operand']] if filter['operator'] == 'not'
        operand = STRING_OPERATOR_DEFINITIONS[filter['operator']]
        params = operand.gsub('_', c) if operand
      when 'boolean'
        raise "Unsupported" unless BOOLEAN_OPERATORS.include?(filter['operator'])
        params = ["#{c} = ?", filter['operator'] == "is_true"]
      when 'datetime', 'date'
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
    clazz # possibly triggers the table not found exception
    if (@generic.tables.index params[:table]) >= 5
      notice = "You're currently on the free plan meant for pet projects which is limited to five tables of your schema.<br/><a href=\"#{current_account.upgrade_link}\" class=\"btn btn-warning\">Upgrade</a> to the startup plan ($10 per month) to access your full schema with Adminium.".html_safe
      if request.xhr?
        render json: {widget: content_tag(:div, notice, class: 'alert'), id: params[:widget_id]}
      else
        redirect_to dashboard_url, notice: notice
      end
    end
  end

  def blank_object object
    object.attributes.keys.each do |key|
      object[key] = nil
    end
    object
  end

  def generate_csv
    keys = clazz.settings.columns[:export]
    options = {col_sep: clazz.settings.export_col_sep}
    out = if clazz.settings.export_skip_header
      ''
    else
      keys.map { |k| clazz.column_display_name k }.to_csv(options)
    end
    @items.find_each do |item|
      out << keys.map do |key|
        if key.include? "."
          parts = key.split('.')
          pitem = item.send(parts.first)
          pitem[parts.second] if pitem
        elsif key.starts_with? 'has_many/'
          key = key.gsub 'has_many/', ''
          foreign_key_name = item.class.original_name.underscore + '_id'
          foreign_key_value = item[item.class.primary_key]
          item.class.generic.table(key).where(foreign_key_name => foreign_key_value).count
        else
          item[key]
        end
      end.to_csv(options)
    end
    out
  end

  def quote_column_name column_name
    @generic.connection.quote_column_name column_name
  end

  def quote_table_name table_name
    @generic.connection.quote_table_name table_name
  end

  def quoted_table_name
    @quoted_table_name ||= quote_table_name clazz.table_name
  end

  def settings_type
    request.format.to_s == 'text/csv' ? :export : :listing
  end

  def after_save_redirection
    return :back if params[:return_to] == 'back'
    redirection = case params[:then_redirect]
    when /edit/
      edit_resource_path(params[:table], @item)
    when /create/
      new_resource_path(params[:table])
    else
      resource_path(params[:table], @item)
    end
  end

end
