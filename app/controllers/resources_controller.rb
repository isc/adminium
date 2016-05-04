class ResourcesController < ApplicationController
  include TimeChartBuilder
  include PieChartBuilder
  include StatChartBuilder
  include Import

  before_action :table_access_limitation, except: :search
  before_action :check_permissions
  before_action :dates_from_params
  before_action :fetch_item, only: %i(show edit download)
  before_action :warn_if_no_primary_key, only: %i(index new)
  helper_method :user_can?, :grouping, :resource, :format_date

  def search
    @items = resource.query
    params[:order] = resource.label_column if resource.label_column.present?
    resource.columns[:search] = [resource.primary_keys, resource.label_column.try(:to_sym)].flatten.compact | resource.columns[:search]
    apply_search
    apply_order
    @items = @items.select(*(resource.columns[:search].map {|c| Sequel.identifier(c)}))
    records = @items.limit(37).map {|h| h.slice(*resource.columns[:search]).merge(adminium_label: resource.item_label(h))}
    render json: {results: records, primary_key: resource.primary_key}
  end

  def index
    @title = params[:table]
    @widget = current_account.table_widgets.where(table: params[:table], advanced_search: params[:asearch]).first
    # FIXME: we could be more specific than *
    @items = resource.query.select qualify(params[:table], Sequel.lit('*'))
    update_export_settings
    apply_where
    apply_filters
    apply_search
    apply_has_many_counts
    apply_order
    page = (params[:page].presence || 1).to_i
    respond_to do |format|
      format.html do
        check_per_page_setting
        @items = @items.extension(:pagination).paginate page, [resource.per_page.to_i, 25].max
        fetch_associated_items
      end
      format.json do
        @items = @items.extension(:pagination).paginate page, 10
        fetch_associated_items
        render json: {
          widget: render_to_string(partial: 'items', locals: {items: @fetched_items, actions_cell: false}),
          id: params[:widget_id],
          total_count: @items.pagination_record_count
        }
      end
      format.csv do
        fetch_associated_items
        response.headers['Content-Disposition'] = 'attachment'
        response.headers['Cache-Control'] = 'no-cache'
        self.response_body = CsvStreamer.new @fetched_items, @associated_items, resource, @resources
      end
    end
  end

  def download
    filename = find_an_extension || "#{params[:table]}-#{params[:key]}-#{params[:id]}.data"
    send_data @item[params[:key].to_sym], filename: filename
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
    @item = if params.key? :clone_id
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
        flash.now[:error] = "Update failed: #{e.message}".html_safe
        @item = item_params.merge resource.primary_key_values_hash(params[:id])
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
      fail 'BulkEditCheckRecordsFailed'
    end
    if @record_ids.one?
      @item = resource.find @record_ids.shift
      @form_url = resource_path(params[:table], resource.primary_key_value(@item), return_to: :back)
      @form_method = 'put'
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

  def chart
    case params[:type]
    when 'TimeChart'
      time_chart
    when 'PieChart'
      pie_chart
    when 'StatChart'
      stat_chart
    else
      render plain: 'cant render this page'
    end
  end

  private

  def find_an_extension
    resource.string_column_names.each do |key|
      return @item[key] if @item[key] =~ /.+(\.\w{1,6})$/
    end
    nil
  end

  def update_export_settings
    if params[:export_columns].present?
      resource.columns[:export] = params[:export_columns].delete_if(&:empty?).map(&:to_sym)
      resource.csv_options = params[:csv_options]
      resource.save
    end
  end

  def check_permissions
    return if admin?
    @permissions = current_collaborator.permissions
    unless user_can? action_name, params[:table]
      respond_to do |format|
        format.html {redirect_to dashboard_url, flash: {error: "You haven't the permission to perform #{action_name} on #{params[:table]}"}}
        format.js {head :forbidden}
      end
    end
  end

  def user_can? action_name, table
    return true if @permissions.nil?
    action_to_perm = {'index' => 'read', 'show' => 'read', 'search' => 'read', 'edit' => 'update', 'update' => 'update', 'new' => 'create', 'create' => 'create', 'destroy' => 'delete', 'bulk_destroy' => 'delete', 'import' => 'create', 'perform_import' => 'create', 'check_existence' => 'read', 'time_chart' => 'read', 'bulk_edit' => 'update', 'bulk_update' => 'update', 'chart' => 'read'}
    @permissions[table.to_s] && @permissions[table.to_s][action_to_perm[action_name.to_s]]
  end

  def fetch_item
    @item = resource.find params[:id]
  rescue Resource::RecordNotFound
    redirect_to resources_path(params[:table]), notice: "#{resource.human_name} ##{params[:id]} does not exist."
  rescue Sequel::DatabaseError => e
    redirect_to resources_path(params[:table]), flash: {error: "Couldn't fetch record with id <b>#{params[:id]}</b>.<br>#{e.message}".html_safe}
  end

  def check_per_page_setting
    per_page = params.delete(:per_page).to_i
    if per_page > 0 && resource.per_page != per_page
      resource.per_page = per_page
      resource.save
    end
  end

  def item_params
    nullify_params
    params[resource.table]
  end

  def nullify_params
    return if @already_nullified
    (params[resource.table] || {}).each do |column_name, value|
      next if value.present? || resource.schema_hash[column_name.to_sym].try(:[], :type) != :string
      nullify_setting = nullify_setting_for column_name
      params[resource.table][column_name] = nil if nullify_setting == 'null'
      params[resource.table].delete column_name if nullify_setting.blank?
    end
    @already_nullified = true
  end

  def nullify_setting_for column_name
    params["#{resource.table}_nullify_settings"].try :[], column_name
  end

  def object_name
    "#{resource.human_name} #<b>#{params[:id] || resource.primary_key_value(@item)}</b>"
  end

  def apply_search
    return unless params[:search].present?
    conds = []
    number_columns = resource.columns[:search].select {|c| resource.number_column?(c)}
    if number_columns.any? && params[:search].match(/\A\-?\d+\Z/)
      v = params[:search].to_i
      conds += number_columns.map {|column| {qualify(resource.table, column) => v}}
    end
    text_columns = resource.columns[:search].select {|c| resource.text_column?(c)}
    if text_columns.any?
      string_patterns = params[:search].split(' ').map {|pattern| pattern.include?('%') ? pattern : "%#{pattern}%" }
      conds << resource.query.grep(text_columns.map {|c| qualify(resource.table, c)}, string_patterns, case_insensitive: true, all_patterns: true).opts[:where]
    end
    array_columns = resource.columns[:search].select {|c| resource.array_column?(c)}
    if array_columns.any?
      search_array = @generic.db.literal Sequel.pg_array(params[:search].split(' '), :text)
      conds += array_columns.map {|column| Sequel.lit "\"#{column}\"::text[] @> #{search_array}"}
    end
    uuid_columns = resource.columns[:search].select {|c| resource.uuid_column?(c)}
    if uuid_columns.any? && params[:search].match(/\A[a-f\d\-]+\Z/)
      no_hyphens = params[:search].delete('-')
      cond = if no_hyphens =~ /\A.{32}\Z/
               no_hyphens
             elsif (padding = 32 - no_hyphens.size).positive?
               (no_hyphens + '0' * padding)..(no_hyphens + 'f' * padding)
             end
      conds += uuid_columns.map {|column| {column => cond}} if cond
    end
    if conds.any?
      @items = @items.filter(Sequel::SQL::BooleanExpression.new(:OR, *conds))
    else
      flash.now[:error] = "The value <b>#{params[:search]}</b> cannot be searched for on the following column(s) : #{resource.columns[:search].join(', ')}."
    end
  end

  def apply_where
    @items = @items.where(datname: @generic.db_name) if pg_stat_activity?
    return unless params[:where].present?
    where_hash = Hash[params[:where].map do |k, v|
      v = nil if v == 'null'
      if v.is_a? Hash
        flash.now[:error] = 'Invalid <i>where</i> parameter value.'
        params[:where].delete k
        next
      end
      if resource.date_column? k.to_sym
        # FIXME: application time zone is not factored in
        [time_chart_aggregate(qualify(params[:table], k)), v]
      else
        if k['.']
          table, k = k.split('.')
          join_belongs_to table
        else
          table = resource.table
        end
        if resource_for(table).column_names.include? k.to_sym
          [qualify(table, k.to_sym), v]
        else
          params[:where].delete k
          flash.now[:error] = "Column <i>#{k}</i> doesn't exist on table #{table}.<br>Existing columns are <i>#{resource_for(table).column_names.join(', ')}</i>.".html_safe
        end
      end
    end.compact]
    @items = @items.where(where_hash)
  end

  def fetch_associated_items
    @fetched_items = @items.to_a
    @associated_items = {}
    # FIXME: polymorphic belongs_to generate N+1 queries (since no referenced_table in assoc_info)
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
      assoc_info = resource.associations[:has_many].detect {|name, _| name.to_s == assoc}.second
      next if assoc_info.nil?
      count_on = qualify_primary_keys resource_for(assoc)
      @items = @items
               .left_outer_join(assoc.to_sym, qualify(assoc_info[:table], assoc_info[:foreign_key]) => qualify(assoc_info[:referenced_table], assoc_info[:primary_key]))
               .group(qualify_primary_keys(resource))
               .select_append(Sequel.function(:count, Sequel.function(:distinct, *count_on)).as(column))
    end
  end

  def apply_order
    order = params[:order] || resource.default_order
    return unless order
    column, descending = order.split ' '
    if column['.']
      join_belongs_to column.split('.').first
      @items = @items.select_append Sequel.lit(column)
    end
    column = case order
             when /\./
               Sequel.lit(column)
             when /\//
               column.to_sym
             else
               (qualify params[:table], column)
             end
    opts = @generic.mysql? ? {} : {nulls: :last}
    @items = @items.order(Sequel::SQL::OrderedExpression.new(column, !!descending, opts))
    @items = @items.order_prepend(Sequel.case([[{column => nil}, 1]], 0)) if @generic.mysql?
  end

  def apply_filters
    @current_filter = resource.filters[params[:asearch]] || []
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
      'null' => {operator: :IS, right: nil},
      'not_null' => {operator: :'IS NOT', right: nil},
      'is_true' => {operator: :'=', right: true},
      'is_false' => {operator: :'=', right: false},
      '!=' => {operator: :'!='},
      '=' => {operator: :'='},
      '>' => {operator: :>},
      '>=' => {operator: :>=},
      '<' => {operator: :<},
      '<=' => {operator: :<=},
      'IN' => {operator: :IN, right: filter['operand'].to_s.split(/[, ]/).map(&:strip).delete_if(&:empty?)},
      'is' => {operator: :'='},
      'blank' => {specific: 'blank'},
      'present' => {specific: 'present'}
    }
    if filter['assoc'].present?
      assoc = resource.associations[:belongs_to].detect {|k, _| k.to_s == filter['assoc']}
      resource_with_column = resource_for assoc.second[:referenced_table]
      join_belongs_to assoc.first
      table = assoc.second[:referenced_table]
    else
      resource_with_column, table = resource, params[:table]
    end
    column_info = resource_with_column.column_info(filter['column'].to_sym)
    type = column_info[:type] || column_info[:db_type]
    if type.to_sym != filter['type'].to_sym
      flash.now[:error] = "Filter on the #{filter['column']} column is not valid anymore (defined on a #{filter['type']} column, not #{type})."
      return
    end
    operators.merge! datetime_operators if %i(date datetime).index(type)
    operators.merge! string_operators if %i(string text).index(type)
    column = qualify table, filter['column'].to_sym
    operation = operators[filter['operator']]
    column = Sequel.function operation[:named_function], column if operation[:named_function]
    return send("apply_filter_#{operation[:specific]}", column) if operation[:specific]
    return Sequel::SQL::BooleanExpression.from_value_pairs column => operation[:right] if operation[:boolean_operator]
    return Sequel::SQL::ComplexExpression.new operation[:operator], column, right_value(operation, filter['operand']) if operation[:operator]
  end

  def string_operators
    {
      'like' => {operator: :ILIKE, replace_right: '%_%'},
      'not_like' => {operator: :'NOT ILIKE', replace_right: '%_%'},
      'starts_with' => {operator: :ILIKE, replace_right: '_%'},
      'ends_with' => {operator: :ILIKE, replace_right: '%_'},
      'not' => {operator: :'!='}
    }
  end

  # FIXME: not taking into account the time zone settings of the account
  def datetime_operators
    today = Date.current
    {
      'today' => {operator: :'=', right: today, named_function: 'DATE'},
      'yesterday' => {operator: :'=', right: 1.day.ago.to_date, named_function: 'DATE'},
      'this_week' =>
        {boolean_operator: true, right: (today.beginning_of_week)..(today.end_of_week), named_function: 'DATE'},
      'last_week' =>
        {boolean_operator: true, right: (1.week.ago.to_date.beginning_of_week)..(1.week.ago.to_date.end_of_week), named_function: 'DATE'},
      'on' => {operator: :'=', named_function: 'DATE', right_function: 'to_date'},
      'not' => {operator: :'!=', named_function: 'DATE', right_function: 'to_date'},
      'after' => {operator: :'>', named_function: 'DATE', right_function: 'to_date'},
      'before' => {operator: :'<', named_function: 'DATE', right_function: 'to_date'}
    }
  end

  def apply_filter_blank column
    is_null = Sequel::SQL::ComplexExpression.new(:IS, column, nil)
    is_blank = Sequel::SQL::ComplexExpression.new(:'=', column, '')
    Sequel::SQL::ComplexExpression.new(:OR, is_null, is_blank)
  end

  def apply_filter_present column
    is_not_null = Sequel::SQL::ComplexExpression.new(:'IS NOT', column, nil)
    is_not_blank = Sequel::SQL::ComplexExpression.new(:'!=', column, '')
    Sequel::SQL::ComplexExpression.new(:AND, is_not_null, is_not_blank)
  end

  def right_value operation, value
    return operation[:right] if operation.key?(:right)
    return operation[:replace_right].gsub('_', value.gsub('_', '\\_')) if operation.key?(:replace_right)
    return Date.parse value if operation[:right_function] == 'to_date'
    value
  end

  def table_access_limitation
    return unless current_account.pet_project?
    @generic.table params[:table] # possibly triggers the table not found exception
    if (@generic.tables.index params[:table].to_sym) >= 5
      notice = "You are currently on the free plan meant for pet projects which is limited to five tables of your schema.<br/><a href=\"#{current_account.upgrade_link}\" class=\"btn btn-warning\">Upgrade</a> to the startup plan ($10 per month) to access your full schema with Adminium.".html_safe
      if request.xhr?
        render json: {widget: view_context.content_tag(:div, notice, class: 'alert alert-warning'), id: params[:widget_id]}
      else
        redirect_to dashboard_url, flash: {warning: notice}
      end
    end
  end

  def join_belongs_to assoc_name
    @joined_belongs_to ||= []
    return if @joined_belongs_to.include? assoc_name.to_sym
    @joined_belongs_to << assoc_name.to_sym
    assoc_info = resource.associations[:belongs_to][assoc_name.to_sym]
    @items = @items.left_outer_join(assoc_info[:referenced_table], assoc_info[:primary_key] => qualify(params[:table], assoc_info[:foreign_key]))
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
    primary_key = resource.primary_key_value(item_params) || params[:id]
    case params[:then_redirect]
    when /edit/
      edit_resource_path(params[:table], primary_key)
    when /create/
      new_resource_path(params[:table])
    else
      if primary_key # there can be no id if no primary key on the table
        resource_path(params[:table], primary_key)
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
      next unless value.is_a? Hash
      if value.key?('date') && value['date'].blank? || (!value.key?('date') && value.key?('4i') && value['4i'].blank?)
        item_params[key] = nil
      else
        res = ''
        res << value['date'] if value.key?('date')
        item_params[key] = if value['4i']
                             application_time_zone.parse "#{res} #{value['4i']}:#{value['5i']}"
                           else
                             Date.parse res
                           end
      end
    end
  end

  def warn_if_no_primary_key
    flash.now[:warning] = "Warning : this table doesn't declare a primary key. Support for tables without primary keys is incomplete at the moment." if resource.primary_keys.empty? && !resource.system_table?
  end

  def application_time_zone
    @application_time_zone ||= ActiveSupport::TimeZone.new current_account.application_time_zone
  end

  def pg_stat_activity?
    params[:table] == 'pg_stat_activity'
  end
end
