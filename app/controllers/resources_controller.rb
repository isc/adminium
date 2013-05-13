class ResourcesController < ApplicationController

  include TimeChartBuilder
  include Import

  before_filter :table_access_limitation, except: [:search]
  before_filter :check_permissions
  before_filter :dates_from_params
  before_filter :fetch_item, only: [:show, :edit]
  before_filter :warn_if_no_primary_key, only: [:index, :new]
  helper_method :user_can?
  helper_method :grouping, :resource

  respond_to :json, only: [:perform_import, :check_existence, :search]
  respond_to :json, :html, only: [:index, :update]
  respond_to :csv, only: :index

  def search
    @items = resource.query
    params[:order] = resource.label_column if resource.label_column.present?
    resource.columns[:search] = [resource.primary_keys, resource.label_column.try(:to_sym)].flatten.compact | resource.columns[:search]
    apply_search
    apply_order
    @items = @items.select(*(resource.columns[:search].map {|c| Sequel.identifier(c)}))
    records = @items.paginate(1, 37).map {|h| h.merge(adminium_label: resource.item_label(h))}
    render json: records.to_json(only: resource.columns[:search] + [:adminium_label])
  end

  def index
    @title = params[:table]
    @current_filter = resource.filters[params[:asearch]] || []
    @widget = current_account.table_widgets.where(table: params[:table], advanced_search: params[:asearch]).first
    # FIXME we could be more specific than *
    @items = resource.query.select(qualify params[:table], Sequel.lit('*'))
    update_export_settings
    apply_where
    apply_filters
    apply_search
    @items_for_stats = @items
    apply_has_many_counts
    apply_order
    page = (params[:page].presence || 1).to_i
    respond_with @items do |format|
      format.html do
        check_per_page_setting
        @items = @items.paginate page, resource.per_page.to_i
        fetch_associated_items
        apply_statistics
      end
      format.json do
        @items = @items.paginate page, 10
        fetch_associated_items
        render json: {
          widget: render_to_string(partial: 'items', locals: {items: @fetched_items, actions_cell: false}),
          id: params[:widget_id],
          total_count: @items.pagination_record_count
        }
      end
      format.csv do
        fetch_associated_items
        send_data generate_csv, type: 'text/csv'
      end
    end
  end

  def show
    @title = "Show #{resource.item_label @item}"
    @prevent_truncate = true
  end

  def edit
    @title = "Edit #{resource.item_label @item}"
    @form_url = resource_path(params[:table], resource.primary_key_value(@item))
    @form_method = 'put'
  end

  def new
    @title = "New #{params[:table].humanize.singularize}"
    @form_url = resources_path(params[:table])
    @item = if params.has_key? :clone_id
      attrs = resource.find(params[:clone_id])
      attrs.delete_if {|key, _| resource.primary_keys.include? key} 
      attrs
    else
      params[:attributes] || {}
    end
  end

  def create
    pk_value = resource.insert item_params
    params[:id] = pk_value
    redirect_to after_save_redirection, flash: {success: "#{object_name} successfully created."}
  rescue Sequel::Error, Resource::ValidationError => e
    flash.now[:error] = e.message.html_safe
    @item = item_params
    @form_url = resources_path params[:table]
    render :new
  end

  def update
    resource.update_item params[:id], item_params
    respond_to do |format|
      format.html do
        redirect_to after_save_redirection, flash: {success: "#{object_name} successfully updated."}
      end
      format.json do
        column_name = item_params.keys.first.to_sym
        value = view_context.display_attribute :td, resource.find(params[:id]), column_name, resource
        render json: {result: :success, value: value, column: column_name, id: params[:id]}
      end
    end
  rescue Sequel::Error, Resource::ValidationError => e
    respond_to do |format|
      format.html do
        flash.now[:error] = e.message.html_safe
        @item = item_params.merge(resource.primary_key_values_hash params[:id])
        @form_url = resource_path(params[:table], params[:id])
        @form_method = 'put'
        render :edit
      end
      format.json do
        column_name = item_params.keys.first
        render json: {result: :failed, message: e.message, column: column_name, id: params[:id]}
      end
    end
  end

  def destroy
    resource.delete params[:id]
    redirection = params[:redirect] == 'index' ? resources_path(params[:table]) : :back
    redirect_to redirection, flash: {success: "#{object_name} successfully destroyed."}
  rescue Sequel::Error => e
    redirect_to :back, flash: {error: e.message}
  end

  def bulk_destroy
    params[:item_ids].map! {|id| id.split(',')} if resource.composite_primary_key?
    resource.delete params[:item_ids]
    redirect_to :back, flash: {success: "#{params[:item_ids].size} #{resource.human_name.pluralize} successfully destroyed."}
  rescue Sequel::Error => e
    redirect_to :back, flash: {error: e.message}
  end

  def bulk_edit
    @record_ids = params[:record_ids]
    if resource.query.where(resource.primary_key => params[:record_ids]).count != @record_ids.length
      raise "BulkEditCheckRecordsFailed"
    end
    if @record_ids.length == 1
      @item = resource.find @record_ids.shift
      @form_url = resource_path(params[:table], resource.primary_key_value(@item), return_to: :back)
    else
      @form_url = bulk_update_resources_path(params[:table])
      @item = {}
    end
    render layout: false
  end

  def bulk_update
    count = resource.update_multiple_items params[:record_ids], (item_params || {})
    redirect_to :back, flash: {success: "#{count || 0} rows have been updated"}
  end

  def test_threads
    Account.find_by_sql 'select pg_sleep(10)'
    render json: @generic.table('accounts').first.inspect
  end

  private

  def update_export_settings
    if params[:export_columns].present?
      resource.columns[:export] = params[:export_columns].delete_if{|e|e.empty?}.map(&:to_sym)
      resource.csv_options = params[:csv_options]
      resource.save
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
    action_to_perm = {'index' => 'read', 'show' => 'read', 'search' => 'read', 'edit' => 'update', 'update' => 'update', 'new' => 'create', 'create' => 'create', 'destroy' => 'delete', 'bulk_destroy' => 'delete', 'import' => 'create', 'perform_import' => 'create', 'check_existence' => 'read'}
    @permissions[table] && @permissions[table][action_to_perm[action_name]]
  end

  def fetch_item
    @item = resource.find params[:id]
  rescue Resource::RecordNotFound
    redirect_to resources_path(params[:table]), notice: "#{resource.human_name} ##{params[:id]} does not exist."
  end

  def check_per_page_setting
    per_page = params.delete(:per_page).to_i
    if per_page > 0 && resource.per_page != per_page
      resource.per_page = per_page
      resource.save
    end
  end

  def item_params
    params[resource.table]
  end

  def object_name
    "#{resource.human_name} ##{params[:id] || resource.primary_key_value(@item)}"
  end

  def apply_statistics
    @projections = []
    @select_values = []
    apply_number_statistics
    apply_enum_statistics
    apply_boolean_statistics
    return if @projections.empty?
    @statistics = {}
    begin
      first_projection = @projections.shift
      @items_for_stats = @items_for_stats.select(first_projection)
      @projections.each do |projection|
        @items_for_stats = @items_for_stats.select_append(projection)
      end
      @items_for_stats.all.first.values.each_with_index do |value, index|
        column, calculation = @select_values[index]
        @statistics[column] ||= {}
        value = value.to_s.index('.') ? ((value.to_f * 100).round / 100.0) : value.to_i if value.present?
        @statistics[column][calculation] = value
      end
    rescue => ex
      if Rails.env.production?
        notify_airbrake ex
      else
        raise ex
      end
    end
  end

  def apply_boolean_statistics
    resource.schema_hash.each do |name,c|
      next unless (c[:type] == :boolean) && resource.columns[:listing].include?(name)
      [true, false, nil].each do |value|
        @projections.push sum_case_when(name, value)
        value = value.nil? ? 'null' : value.to_s
        @select_values.push [name, value]
      end
    end
  end
  
  def sum_case_when c, x
    Sequel.as(Sequel.function(:sum, Sequel.case({{qualify(resource.table, c) => x} => 1}, 0)), "c#{rand(1000)}")
  end
  
  def apply_enum_statistics
    resource.schema_hash.each do |name,c|
      enum_values = resource.enum_values_for(name)
      next if enum_values.blank?
      enum_values.each do |key, value|
        @projections.push sum_case_when(name, key)
        @select_values.push [name, value]
      end
    end
  end

  def apply_number_statistics
    statistics_columns = []
    resource.schema.each do |name, info|
      if [:integer, :float, :decimal].include?(info[:type]) && !name.to_s.ends_with?('_id') &&
        resource.enum_values_for(name).nil? && resource.columns[:listing].include?(name) &&
        !resource.primary_keys.include?(name)
        statistics_columns.push name
      end
    end
    @projections += statistics_columns.map do |column_name|
      quoted_column = qualify(resource.table, column_name)
      ['max', 'min', 'avg'].map do |calculation|
        @select_values.push [column_name, calculation]
        Sequel.as(Sequel.function(calculation.to_sym, quoted_column), "d#{rand(1000)}")
      end
    end.flatten
  end

  def apply_search
    return unless params[:search].present?
    number_columns = resource.columns[:search].select{|c| resource.is_number_column?(c)}
    if number_columns.present? && params[:search].match(/\A\-?\d+\Z/)
      v = params[:search].to_i
      @items = @items.where(false)
      number_columns.each do |column|
        @items = @items.or(qualify(resource.table, column) => v)
      end
    else
      text_columns = resource.columns[:search].select{|c| resource.is_text_column?(c)}
      if text_columns.present?
        string_patterns = params[:search].split(" ").map {|pattern| pattern.include?("%") ? pattern : "%#{pattern}%" }
        @items = @items.grep(text_columns.map{|c| qualify(resource.table, c)}, string_patterns, case_insensitive: true, all_patterns: true)
      end
    end
  end
  
  def apply_where
    return unless params[:where].present?
    where_hash = Hash[params[:where].map {|k, v| [qualify(resource.table, k.to_sym), v]}]
    @items = @items.where(where_hash)
  end

  def fetch_associated_items
    @fetched_items = @items.to_a
    @associated_items = {}
    # FIXME polymorphic belongs_to generate N+1 queries (since no referenced_table in assoc_info) 
    referenced_tables = resource.columns[settings_type].map do |c|
      if c.to_s.include?('.')
        c.to_s.split('.').first.to_sym
      else
        table = resource.foreign_key?(c).try(:[], :referenced_table)
        table if table && resource_for(table).label_column
      end
    end
    referenced_tables.compact.uniq.map do |referenced_table|
      fetch_items_for_assoc @fetched_items, resource.associations[:belongs_to][referenced_table]
    end
    resource.columns[settings_type].each do |c|
      next unless c.to_s.include?('.')
      table, column = c.to_s.split('.').map(&:to_sym)
      assoc = resource_for(table).foreign_key? column
      fetch_items_for_assoc @associated_items[table], assoc if assoc && resource_for(assoc[:referenced_table]).label_column
    end
  end
  
  def fetch_items_for_assoc items, assoc_info
    ids = items.map {|i| i[assoc_info[:foreign_key]]}.uniq
    resource = resource_for assoc_info[:referenced_table]
    @associated_items[resource.table] = resource.query.where(resource.primary_keys.first => ids).all
  end

  def apply_has_many_counts
    resource.columns[settings_type].find_all {|c| c.to_s.starts_with? 'has_many/'}.each do |column|
      assoc = column.to_s.gsub 'has_many/', ''
      assoc_info = resource.associations[:has_many].detect {|name, info| name.to_s == assoc}.second
      next if assoc_info.nil?
      count_on = qualify_primary_keys resource_for(assoc)
      @items = @items
        .left_outer_join(assoc.to_sym, qualify(assoc_info[:table], assoc_info[:foreign_key]) => qualify(assoc_info[:referenced_table], assoc_info[:primary_key]))
        .group(qualify_primary_keys resource)
        .select_append(Sequel.function(:count, Sequel.function(:distinct, *count_on)).as(column))
    end
  end

  def apply_order
    order  = params[:order] || resource.default_order
    return unless order
    column, descending = order.split(" ")
    column = order[/[.\/]/] ? column.to_sym : (qualify params[:table], column)
    opts = @generic.mysql? ? {} : {nulls: :last}
    @items = @items.order(Sequel::SQL::OrderedExpression.new(column, !!descending, opts))
    @items = @items.order_prepend(Sequel.case([[{column=>nil}, 1]], 0)) if @generic.mysql?
  end

  def apply_filters
    @current_filter.each_with_index do |filter, index|
      clause = apply_filter filter
      @items = if index.nonzero? && filter['grouping'] == 'or'
        @items.or(clause)
      else
        @items.where(clause)
      end
    end
  end

  def apply_filter filter
    operators = {
      'null' => {:operator => :IS, :right => nil},
      'not_null' => {:operator => :'IS NOT', :right => nil},
      'is_true' => {:operator => :'=', :right => true},
      'is_false' => {:operator => :'=', :right => false},
      '!=' => {:operator => :'!='},
      '=' => {:operator => :'='},
      '>' => {:operator => :>},
      '>=' => {:operator => :>=},
      '<' => {:operator => :<},
      '<=' => {:operator => :<=},
      'IN' => {:operator => :IN, :right => filter['operand'].to_s.split(',').map(&:strip)},
      'is' => {:operator => :'='},
      'blank' => {:specific => 'blank'},
      'present' => {:specific => 'present'}
    }
    type = resource.column_info(filter['column'].to_sym)[:type]
    operators.merge! datetime_operators if [:date, :datetime].index(type)
    operators.merge! string_operators if [:string, :text].index(type)
    column = qualify params[:table], filter['column'].to_sym
    operation = operators[filter['operator']]
    if operation[:named_function]
      column = Sequel.function operation[:named_function], column
    end
    return send("apply_filter_#{operation[:specific]}", column) if operation[:specific]
    return Sequel::SQL::BooleanExpression.from_value_pairs({column => operation[:right]}) if operation[:boolean_operator]
    return Sequel::SQL::ComplexExpression.new operation[:operator], column, right_value(operation, filter['operand']) if operation[:operator]
  end

  def string_operators
    {
      'like' => {:operator => :ILIKE, :replace_right => "%_%"},
      'not_like' => {:operator => :'NOT ILIKE', :replace_right => '%_%'},
      'starts_with' => {:operator => :ILIKE, :replace_right => "_%"},
      'ends_with' => {:operator => :ILIKE, :replace_right => "%_"},
      'not' => {:operator => :'!='}
    }
  end

  def datetime_operators
    today = Date.today
    {
      'today' => {:operator => :'=', :right => today, :named_function => "DATE"},
      'yesterday' => {:operator => :'=', :right => 1.day.ago.to_date, :named_function => "DATE"},
      'this_week' =>
        {boolean_operator: true, right: (today.beginning_of_week)..(today.end_of_week), named_function: 'DATE'},
      'last_week' =>
        {boolean_operator: true, right: (1.week.ago.to_date.beginning_of_week)..(1.week.ago.to_date.end_of_week), named_function: 'DATE'},
      'on' => {:operator => :'=', :named_function => "DATE", :right_function => 'to_date'},
      'not' => {:operator => :'!=', :named_function => "DATE", :right_function => 'to_date'},
      'after' => {:operator => :'>', :named_function => "DATE", :right_function => 'to_date'},
      'before' => {:operator => :'<', :named_function => "DATE", :right_function => 'to_date'}
    }
  end

  def apply_filter_blank column
    is_null = Sequel::SQL::ComplexExpression.new(:'IS', column, nil)
    is_blank = Sequel::SQL::ComplexExpression.new(:'=', column, '')
    Sequel::SQL::ComplexExpression.new(:OR, is_null, is_blank)
  end

  def apply_filter_present column
    is_not_null = Sequel::SQL::ComplexExpression.new(:'IS NOT', column, nil)
    is_not_blank = Sequel::SQL::ComplexExpression.new(:'!=', column, '')
    Sequel::SQL::ComplexExpression.new(:AND, is_not_null, is_not_blank)
  end

  def right_value operation, value
    return operation[:right] if operation.has_key?(:right)
    return operation[:replace_right].gsub('_', value) if operation.has_key?(:replace_right)
    return Date.strptime(value, '%m/%d/%Y') if operation[:right_function] == 'to_date'
    return value
  end

  def table_access_limitation
    return unless current_account.pet_project?
    @generic.table params[:table] # possibly triggers the table not found exception
    if (@generic.tables.index params[:table].to_sym) >= 5
      notice = "You're currently on the free plan meant for pet projects which is limited to five tables of your schema.<br/><a href=\"#{current_account.upgrade_link}\" class=\"btn btn-warning\">Upgrade</a> to the startup plan ($10 per month) to access your full schema with Adminium.".html_safe
      if request.xhr?
        render json: {widget: view_context.content_tag(:div, notice, class: 'alert'), id: params[:widget_id]}
      else
        redirect_to dashboard_url, notice: notice
      end
    end
  end

  def generate_csv
    keys = resource.columns[:export]
    options = {col_sep: resource.export_col_sep}
    out = if resource.export_skip_header
      ''
    else
      keys.map { |k| resource.column_display_name k }.to_csv(options)
    end
    @items.each do |item|
      out << keys.map do |key|
        if key.to_s.include? '.'
          referenced_table, column = key.to_s.split('.').map(&:to_sym)
          assoc = resource.associations[:belongs_to][referenced_table]
          pitem = @associated_items[referenced_table].find {|i| i[assoc[:primary_key]] == item[assoc[:foreign_key]]}
          pitem[column] if pitem
        else
          item[key]
        end
      end.to_csv(options)
    end
    out
  end

  def qualify table, column
    Sequel.identifier(column).qualify table
  end
  
  def qualify_primary_keys resource
    resource.primary_keys.map {|key| qualify(resource.table, key)}
  end

  def settings_type
    request.format.to_s == 'text/csv' ? :export : :listing
  end

  def after_save_redirection
    return :back if params[:return_to] == 'back'
    case params[:then_redirect]
    when /edit/
      edit_resource_path(params[:table], params[:id])
    when /create/
      new_resource_path(params[:table])
    else
      id = params[:id] || resource.primary_key_value(@item)
      if id # there can be no id if no primary key on the table
        resource_path(params[:table], id)
      else
        resources_path params[:table]
      end
    end
  end

  def resource
    resource_for params[:table]
  end

  def dates_from_params
    return unless item_params.present?
    item_params.each do |key, value|
      if value.is_a? Hash
        if value.has_key?('1i') && value['1i'].blank? || value['4i'].blank?
          item_params[key] = nil
        else
          res = ''
          if value.has_key?('1i')
            res << "#{value['1i']}-#{value['2i']}-#{value['3i']}"
          end
          item_params[key] = if value['4i']
            Time.parse "#{res} #{value['4i']}:#{value['5i']}"
          else
            Date.parse date
          end
        end
      end
    end
  end
  
  def warn_if_no_primary_key
    flash.now[:warning] = "Warning : this table doesn't declare a primary key. Support for tables without primary keys is incomplete at the moment." if resource.primary_keys.empty?
  end

end