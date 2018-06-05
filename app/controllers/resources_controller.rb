class ResourcesController < ApplicationController
  include TimeChartBuilder
  include PieChartBuilder
  include StatChartBuilder
  include Import

  before_action :table_access_limitation, except: :search
  before_action :check_permissions
  before_action :dates_from_params
  before_action :fetch_item, only: %i(show edit download update)
  before_action :warn_if_no_primary_key, only: %i(index new)
  before_action :check_column, only: :chart
  helper_method :user_can?, :grouping, :resource, :format_date, :permitted_columns

  def search
    @items = resource.query
    params[:order] = resource.label_column if resource.label_column.present?
    resource.columns[:search] |= [resource.primary_keys, resource.label_column&.to_sym, params[:primary_key].to_sym].flatten.compact
    apply_search
    apply_order
    @items = @items.select(*(resource.columns[:search].map {|c| Sequel.identifier(c)}))
    records = @items.limit(37).map {|h| h.slice(*resource.columns[:search]).merge(adminium_label: resource.item_label(h))}
    render json: {results: records, primary_key: params[:primary_key]}
  end

  def index
    @title = params[:table]
    @widget = current_account.table_widgets.where(table: params[:table], advanced_search: params[:asearch]).first
    @items = resource.query
    update_export_settings
    apply_select
    dataset_filtering
    apply_has_many_counts
    apply_order
    handle_pagination
    fetch_associated_items
    respond_to do |format|
      format.html
      format.json do
        render json: {
          widget: render_to_string(partial: 'items', locals: {items: @fetched_items, actions_cell: false}),
          id: params[:widget_id],
          total_count: @total_count
        }
      end
      format.csv do
        response.headers['Content-Disposition'] = "attachment; filename=#{params[:table]}.csv"
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
    @strings_and_hstore_cols = item_attributes_type %i(string varchar_array string_array hstore)
    @numbers_cols = item_attributes_type %i(integer float decimal)
    dates_and_times_cols = item_attributes_type %i(date datetime time timestamp)
    @pks_dates_and_times_cols = (resource.columns[:show] & resource.primary_keys) + dates_and_times_cols
    @boolean_and_blob_cols = item_attributes_type %i(boolean blob)
    @leftover_cols = resource.columns[:show] -
                     @strings_and_hstore_cols - @numbers_cols - @pks_dates_and_times_cols - @boolean_and_blob_cols -
                     resource.belongs_to_associations.map {|assoc| assoc[:foreign_key]}
    @table_configuration = current_account.table_configurations.find_or_create_by(table: resource.table)
    @candidates_for_polymorphic_associations = @table_configuration.candidates_for_polymorphic_associations @generic
    @has_many_associations = resource.has_many_associations +
                             @table_configuration.polymorphic_associations_as_hashes(resource.primary_keys.first)
    @has_many_associations.sort_by! {|assoc| assoc[:table].to_s}
  end

  def edit
    @title = "Edit #{resource.item_label @item}"
    @form_url = resource_path(params[:table], resource.primary_key_value(@item))
    @form_method = 'put'
  end

  def new
    @title = "New #{resource.human_name}"
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
    after_save_redirection flash: {success: "#{ERB::Util.h object_name} successfully created."}
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
        after_save_redirection flash: {success: "#{ERB::Util.h object_name} successfully updated."}
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
    options = {flash: {success: "#{ERB::Util.h object_name} successfully destroyed."}}
    if params[:redirect] == 'index'
      redirect_to resources_path(params[:table]), options
    else
      redirect_back fallback_location: resources_path(params[:table]), **options
    end
  rescue Sequel::Error => e
    redirect_back fallback_location: resources_path(params[:table]), flash: {error: e.message}
  end

  def bulk_destroy
    params[:item_ids].map! {|id| id.split(',')} if resource.composite_primary_key?
    resource.delete params[:item_ids]
    redirect_back fallback_location: resources_path(params[:table]),
                  flash: {success: "#{params[:item_ids].size} #{resource.human_name.pluralize} successfully destroyed"}
  rescue Sequel::Error => e
    redirect_back fallback_location: resources_path(params[:table]), flash: {error: e.message}
  end

  def bulk_edit
    @record_ids = params[:record_ids]
    if resource.query.where(resource.primary_key => params[:record_ids]).count != @record_ids.length
      raise 'BulkEditCheckRecordsFailed'
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
    redirect_back fallback_location: resources_path(params[:table]),
                  flash: {success: "#{count || 0} rows have been updated"}
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

  def dataset_filtering
    apply_where
    apply_exclude
    apply_filters
    apply_search
  end

  def find_an_extension
    resource.string_column_names.each do |key|
      return @item[key] if @item[key] =~ /.+(\.\w{1,6})$/
    end
    nil
  end

  def update_export_settings
    return if params[:export_columns].blank?
    resource.columns[:export] = params[:export_columns].delete_if(&:empty?).map(&:to_sym)
    resource.csv_options = params[:csv_options]
    resource.save
  end

  def fetch_item
    @item = resource.find params[:id], fetch_binary_values: (params[:action] == 'download')
  rescue Resource::RecordNotFound
    message = "#{resource.human_name} ##{params[:id]} does not exist."
    respond_to do |format|
      format.html {redirect_to resources_path(params[:table]), notice: message}
      format.js {render json: {message: message}}
    end
  rescue Sequel::DatabaseError => e
    redirect_to resources_path(params[:table]), flash: {error: "Couldn't fetch record with id <b>#{ERB::Util.h params[:id]}</b>.<br>#{ERB::Util.h e.message}".html_safe}
  end

  def check_per_page_setting
    per_page = params.delete(:per_page).to_i
    return if per_page <= 0 || resource.per_page == per_page
    resource.per_page = per_page
    resource.save
  end

  def item_params
    @item_params ||= nullify_params params[resource.table]&.to_unsafe_h
  end

  def nullify_params item_params
    return unless item_params
    item_params.each do |column_name, value|
      next if value.present? || resource.schema_hash[column_name.to_sym].try(:[], :type) != :string
      nullify_setting = params["#{resource.table}_nullify_settings"].try :[], column_name
      item_params[column_name] = nil if nullify_setting == 'null'
      item_params.delete column_name if nullify_setting.blank?
    end
    item_params
  end

  def object_name
    "#{resource.human_name} #<b>#{params[:id] || resource.primary_key_value(@item)}</b>"
  end

  def apply_search
    return if params[:search].blank?
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

  def apply_select
    columns = permitted_columns.reject {|c| c.to_s.starts_with?('has_many/')}
    columns.map! {|column| column['.'] ? column.to_s.split('.').first.to_sym : column}
    columns.uniq!
    columns |= resource.primary_keys
    columns.map! do |column|
      qualified = qualify params[:table], column
      if resource.binary_column? column
        Sequel.function(:octet_length, qualified).as(column)
      else
        qualified
      end
    end
    @items = @items.select(*columns)
  end

  def apply_where
    if resource.system_table? && resource.column_names.include?(:datname)
      @items = @items.where(datname: @generic.db_name)
    end
    @items = @items.where(schemaname: @generic.search_path) if pg_stat_all_indexes?
    @items = @items.join(:pg_database, oid: :dbid) if pg_stat_statements?
    conditions = process_conditions(:where)
    @items = @items.where(Hash[conditions]) if conditions
  end

  def apply_exclude
    conditions = process_conditions(:exclude)
    return unless conditions
    Hash[conditions].each do |key, value|
      @items = @items.exclude(key => value)
    end
  end

  def process_conditions params_key
    return if params[params_key].blank?
    params[params_key].to_unsafe_h.map do |k, v|
      v = nil if v == 'null'
      if v.is_a? Hash
        flash.now[:error] = "Invalid <i>#{params_key}</i> parameter value."
        params[params_key].delete k
        next
      end
      if v && resource.date_column?(k.to_sym)
        # FIXME: application time zone is not factored in
        v = v.split(' ').first if grouping == 'daily'
        [time_chart_aggregate(qualify(params[:table], k)), v]
      else
        if k['.']
          foreign_key, k = k.split('.')
          table = resource.belongs_to_association(foreign_key.to_sym)[:referenced_table]
          joined_table_alias = join_belongs_to foreign_key
        else
          table = resource.table
        end
        if resource_for(table).column_names.include? k.to_sym
          [qualify(joined_table_alias || table, k.to_sym), v]
        else
          params[params_key].delete k
          flash.now[:error] = "Column <i>#{ERB::Util.h k}</i> doesn't exist on table #{table}.<br>Existing columns are <i>#{resource_for(table).column_names.join(', ')}</i>.".html_safe
        end
      end
    end.compact
  end

  def fetch_associated_items
    @fetched_items = @items.to_a
    @has_many_counts_alias_mapping.each do |column, column_alias|
      @fetched_items.each { |row| row[column] = row.delete(column_alias) }
    end
    @associated_items = {}
    foreign_keys = permitted_columns.map do |c|
      if c.to_s['.']
        c.to_s.split('.').first.to_sym
      elsif resource.foreign_key? c
        # FIXME: polymorphic belongs_to generate N+1 queries (since no referenced_table in assoc_info)
        table = resource.belongs_to_association(c)[:referenced_table]
        c if table && resource_for(table).label_column && user_can?('show', table)
      end
    end
    foreign_keys.compact.uniq.map do |foreign_key|
      fetch_items_for_assoc @fetched_items, resource.belongs_to_association(foreign_key)
    end
    permitted_columns.each do |c|
      next unless c.to_s['.']
      foreign_key, column = c.to_s.split('.').map(&:to_sym)
      assoc = resource.belongs_to_association foreign_key
      assoc = resource_for(assoc[:referenced_table]).foreign_key? column
      next unless assoc && resource_for(assoc[:referenced_table]).label_column
      fetch_items_for_assoc @associated_items[assoc[:table]], assoc
    end
  end

  def fetch_items_for_assoc items, assoc_info
    ids = items.map {|i| i[assoc_info[:foreign_key]]}.uniq.compact
    resource = resource_for assoc_info[:referenced_table]
    # FIXME: fine tune select clause
    @associated_items[resource.table] ||= []
    @associated_items[resource.table] |= resource.query.where(resource.primary_keys.first => ids).all if ids.any?
  end

  def apply_has_many_counts
    @has_many_counts_alias_mapping = {}
    permitted_columns.find_all {|c| c.to_s.starts_with? 'has_many/'}.each do |column|
      assoc_info = resource.find_has_many_association_for_key column
      next if assoc_info.nil?
      table_alias = "#{column}_join"
      aliased_table = Sequel::SQL::AliasedExpression.new(assoc_info[:table], table_alias)
      count_on = qualify_primary_keys resource_for(assoc_info[:table]), table_alias
      @has_many_counts_alias_mapping[column.to_sym] = :"has_many-#{SecureRandom.hex}"
      @items = @items
        .left_outer_join(aliased_table, assoc_info[:foreign_key] => qualify(assoc_info[:referenced_table],
                 assoc_info[:primary_key]))
        .group(qualify_primary_keys(resource))
        .select_append(Sequel.function(:count, Sequel.function(:distinct, *count_on))
        .as(@has_many_counts_alias_mapping[column]))
    end
  end

  def apply_order
    order = params[:order] || resource.default_order
    return unless order
    column, descending = order.split ' '
    if column['.']
      foreign_key, column = column.split '.'
      assoc_info = resource.belongs_to_association foreign_key.to_sym
      joined_table_alias = join_belongs_to assoc_info[:foreign_key]
      nullable = resource_for(assoc_info[:referenced_table]).schema_hash[column.to_sym][:allow_null]
      column = qualify joined_table_alias, column
    elsif order['/']
      nullable = false
      column = @has_many_counts_alias_mapping[column.to_sym]
    else
      nullable = resource.schema_hash[column.to_sym][:allow_null]
      column = qualify params[:table], column
    end
    opts = @generic.postgresql? && nullable ? {nulls: :last} : {}
    @items = @items.order(Sequel::SQL::OrderedExpression.new(column, descending.present?, opts))
    @items = @items.order_prepend(Sequel.case([[{column => nil}, 1]], 0)) if @generic.mysql? && nullable
  end

  def apply_filters
    @searches = current_account.searches.where(params.permit(:table)).to_a.sort_by {|search| search.name.downcase}
    @current_search = @searches.detect {|search| search.name == params[:asearch]}
    return unless @current_search
    @current_search.conditions.each_with_index do |filter, index|
      clause = apply_filter filter
      next unless clause
      @items = index.nonzero? && filter['grouping'] == 'or' ? @items.or(clause) : @items.where(clause)
    end
  end

  def apply_filter filter
    operators = base_operators filter
    if filter['assoc'].present?
      assoc = resource.belongs_to_association filter['assoc'].to_sym
      resource_with_column = resource_for assoc[:referenced_table]
      joined_table_alias = join_belongs_to assoc[:foreign_key]
      table = assoc[:referenced_table]
    else
      resource_with_column, table = resource, params[:table]
    end
    column_info = resource_with_column.column_info(filter['column'].to_sym)
    if column_info.nil?
      flash.now[:error] = "Filter on the #{filter['column']} column is not valid anymore (#{filter['column']} cannot be found on the #{table} table anymore)."
      return
    end
    type = column_info[:type] || column_info[:db_type]
    if type.to_sym != filter['type'].to_sym
      flash.now[:error] = "Filter on the #{filter['column']} column is not valid anymore (defined on a #{filter['type']} column, not #{type})."
      return
    end
    operators.merge! datetime_operators if %i(date datetime).index(type)
    operators.merge! string_operators if %i(string text).index(type)
    operators.merge! array_operators if type.to_s.ends_with? '_array'
    column = qualify(joined_table_alias || table, filter['column'].to_sym)
    operation = operators[filter['operator']]
    column = Sequel.function operation[:named_function], column if operation[:named_function]
    return send("apply_filter_#{operation[:specific]}", column) if operation[:specific]
    return Sequel::SQL::BooleanExpression.from_value_pairs column => operation[:right] if operation[:boolean_operator]
    if operation[:invert_operands]
      return Sequel::SQL::ComplexExpression.new operation[:operator], right_value(operation, filter['operand']), column
    end
    if operation[:operator]
      return Sequel::SQL::ComplexExpression.new operation[:operator], column, right_value(operation, filter['operand'])
    end
  end

  def base_operators filter
    {
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

  def array_operators
    {
      'any' => {operator: :'=', named_function: 'ANY', invert_operands: true},
      'not_any' => {operator: :'!=', named_function: 'ANY', invert_operands: true}
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

  def handle_pagination
    return if request.format.csv?
    if request.format.html?
      @current_page = (params[:page].presence || 1).to_i
      check_per_page_setting
      @page_size = [resource.per_page.to_i, 25].max
    else
      @current_page, @page_size = 1, 10
    end
    @total_count = @generic.with_timeout { @items.count }
    @items = if @total_count
               @items.extension(:pagination).paginate @current_page, @page_size, @total_count
             else
               @items.limit(@page_size, (@current_page - 1) * @page_size)
             end
  end

  def table_access_limitation
    return unless current_account.pet_project?
    @generic.table params[:table] # possibly triggers the table not found exception
    return if @generic.system_table?(params[:table]) || @generic.user_tables.index(params[:table].to_sym) < 5
    notice = "You are currently on the free plan meant for pet projects which is limited to five tables of your schema.<br/><a href=\"#{current_account.upgrade_link}\" class=\"btn btn-warning\">Upgrade</a> to the startup plan ($10 per month) to access your full schema with Adminium.".html_safe
    if request.xhr?
      render json: {widget: view_context.content_tag(:div, notice, class: 'alert alert-warning'), id: params[:widget_id]}
    else
      redirect_to dashboard_url, flash: {warning: notice}
    end
  end

  def join_belongs_to foreign_key
    foreign_key = foreign_key.to_sym
    join_alias = "#{foreign_key}_join"
    @joined_belongs_to ||= []
    return join_alias if @joined_belongs_to.include? foreign_key
    @joined_belongs_to << foreign_key
    assoc_info = resource.belongs_to_association foreign_key
    aliased_join_table = Sequel::SQL::AliasedExpression.new(assoc_info[:referenced_table], join_alias)
    @items = @items.left_outer_join aliased_join_table,
      assoc_info[:primary_key] => qualify(params[:table], assoc_info[:foreign_key])
    join_alias
  end

  def qualify table, column
    Sequel.identifier(column).qualify table
  end

  def qualify_primary_keys resource, table_alias = nil
    resource.primary_keys.map {|key| qualify(table_alias || resource.table, key)}
  end

  def settings_type
    request.format.csv? ? :export : :listing
  end

  def after_save_redirection options
    return redirect_back(fallback_location: resources_path(params[:table]), **options) if params[:return_to] == 'back'
    primary_key = resource.primary_key_value(item_params) || params[:id]
    path =
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
    redirect_to path, options
  end

  def resource
    resource_for params[:table]
  end

  def dates_from_params
    return if item_params.blank?
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
    return if resource.primary_keys.any? || resource.system_table?
    flash.now[:alert] = "Warning : this table doesn't declare a primary key. Support for tables without primary keys is incomplete."
  end

  def application_time_zone
    @application_time_zone ||= ActiveSupport::TimeZone.new current_account.application_time_zone
  end

  def pg_stat_statements?
    params[:table] == 'pg_stat_statements'
  end

  def pg_stat_all_indexes?
    params[:table] == 'pg_stat_all_indexes'
  end

  def item_attributes_type types
    columns = resource.columns[:show]
    columns &= resource.find_all_columns_for_types(*types).map(&:first)
    columns - resource.primary_keys - (resource.belongs_to_associations.map {|assoc| assoc[:foreign_key]})
  end

  def check_column
    return if resource.column_names.include? params[:column].to_sym
    respond_to do |format|
      format.html do
        @missing_column = true
        render layout: false
      end
      format.json do
        render json: { error: "The column #{params[:column]} doesn't exist on table #{params[:table]}.",
                       id: params[:widget_id] }
      end
    end
  end

  def permitted_columns
    @permitted_columns ||= resource.columns[settings_type].select do |column|
      if column['.']
        table = resource.belongs_to_association(column.to_s.split('.').first.to_sym)[:referenced_table]
        user_can? 'show', table
      else
        true
      end
    end
  end
end
