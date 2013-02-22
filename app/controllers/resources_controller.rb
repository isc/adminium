require "activerecord-import/base"

class ResourcesController < ApplicationController

  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::DateHelper
  include ResourcesHelper

  before_filter :table_access_limitation, except: [:search]
  before_filter :check_permissions
  before_filter :apply_serialized_columns, only: [:index, :show]
  before_filter :apply_validations, only: [:create, :update, :new, :edit]
  before_filter :fetch_item, only: [:show, :edit, :update, :destroy]
  helper_method :user_can?

  respond_to :json, only: [:perform_import, :check_existence, :search]
  respond_to :json, :html, only: [:index, :update]
  respond_to :csv, only: :index

  def search
    @items = clazz.select("#{quoted_table_name}.*")
    params[:order] = clazz.settings.label_column if clazz.settings.label_column.present?
    clazz.settings.columns[:search] = [clazz.primary_key, clazz.settings.label_column].compact.map(&:to_s) | clazz.settings.columns[:search]
    apply_search if params[:search].present?
    apply_order
    render json: @items.page(1).per(37).to_json(methods: :adminium_label, :only => ([clazz.primary_key] + clazz.settings.columns[:search]).uniq)
  end

  def index
    @current_filter = clazz.settings.filters[params[:asearch]] || []
    @widget = current_account.widgets.where(table: params[:table], advanced_search: params[:asearch]).first

    @items = clazz
    @items = @items.where(params[:where]) if params[:where].present?
    apply_filters
    apply_includes
    apply_search if params[:search].present?
    @items_for_stats = @items
    @items = @items.select("#{quoted_table_name}.*")
    apply_has_many_counts
    apply_order
    update_export_settings
    respond_with @items do |format|
      format.html do
        check_per_page_setting
        @items = @items.page(params[:page]).per(clazz.settings.per_page)
        apply_statitiscs
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
    data = JSON.parse(params[:data])
    columns = data['headers']
    pkey = clazz.primary_key.to_s
    columns_without_pk = columns.clone
    columns_without_pk.delete pkey
    import_rows = data['create'].present? ? data['create'] : nil
    update_rows = data['update'].present? ? data['update'] : nil
    ActiveRecord::Import.require_adapter(@generic.current_adapter)
    fromId = toId = 0
    updated_ids = []
    begin
      clazz.transaction do
        if import_rows
          clazz.uncached do
            fromId = clazz.select(pkey).last.try pkey || 0
            clazz.import columns_without_pk, import_rows, :validate => false
            toId = clazz.select(pkey).last.try pkey || 0
          end
        end
        if update_rows
          updated_ids = update_from_import(pkey, columns, update_rows)
        end
      end
    rescue => error
      render json: {error: error.to_s}.to_json
      return
    end
    if (import_rows && fromId == toId)
      render json: {error: "No new record were imported"}.to_json
      return
    end
    if (update_rows && updated_ids.blank?)
      render json: {error: "No records were updated"}.to_json
      return
    end
    set_last_import_filter(import_rows, update_rows, fromId, toId, updated_ids)
    result = {success: true}
    render json: result.to_json
  end

  def set_last_import_filter import_rows, update_rows, fromId, toId, updated_ids
    pkey = clazz.primary_key.to_s
    import_filter = []
    if import_rows && update_rows
      created_ids = clazz.where(["(#{pkey} > ?) AND (#{pkey} <= ?)", fromId, toId]).count(:group => pkey).keys
      updated_ids += created_ids
      import_filter.push "column" => pkey, "type"=>"integer", "operator"=>"IN", "operand" => updated_ids.join(',')
    else
      if import_rows
        import_filter.push "column" => pkey, "type" => "integer", "operator"=>">", "operand" => fromId
        import_filter.push "column" => pkey, "type" => "integer", "operator"=>"<=", "operand" => toId
      end
      if update_rows
        import_filter.push "column" => pkey, "type"=>"integer", "operator"=>"IN", "operand" => updated_ids.join(',')
      end
    end
    clazz.settings.filters['last_import'] =  import_filter
    clazz.settings.save
  end

  def check_existence
     ids = params[:id].uniq
     found_items = clazz.count :conditions => {:id => ids}, :group => clazz.primary_key
     not_found_ids = ids - found_items.keys.map(&:to_s)
     if not_found_ids.present?
       result = {error: true, ids: not_found_ids}
     else
       result = {success: true}
     end
     render :json => result.to_json
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
    action_to_perm = {'index' => 'read', 'show' => 'read', 'search' => 'read', 'edit' => 'update', 'update' => 'update', 'new' => 'create', 'create' => 'create', 'destroy' => 'delete', 'bulk_destroy' => 'delete', 'import' => 'create', 'perform_import' => 'create', 'check_existence' => 'read'}
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

  def item_params
    params[clazz.name.underscore.gsub('/', '_')]
  end

  def object_name
    "#{class_name} ##{@item[clazz.primary_key]}"
  end

  def class_name
    clazz.original_name.underscore.humanize
  end

  def apply_statitiscs
    @projections = []
    @select_values = []
    apply_number_statistics
    apply_enum_statistics
    apply_boolean_statitics
    return if @projections.empty?
    @statistics = {}
    begin
      values=clazz.connection.select_rows(@items_for_stats.select(@projections.join(", ")).to_sql).first
      values.each_with_index do |value, index|
        column, calculation = @select_values[index]
        @statistics[column] ||= {}
        value = value.to_s.index('.') ? ((value.to_f * 100).round / 100.0) : value.to_i if value.present?
        @statistics[column][calculation] = value
      end
    rescue => ex
      if Rails.env.production?
        notify_honeybadger(ex)
      else
        raise ex
      end
    end
  end

  def apply_boolean_statitics
    statement = "SUM(CASE WHEN X THEN 1 ELSE 0 END), SUM(CASE WHEN X THEN 0 ELSE 1 END), SUM(CASE WHEN X IS NULL THEN 1 ELSE 0 END)"
    clazz.columns_hash.each do |name,c|
      next if c.type != :boolean
      @projections.push statement.gsub('X', quote_column_name(name)).gsub('Y', name)
      ['true', 'false', 'null'].each do |calculation|
        @select_values.push [name, calculation]
      end
    end
  end

  def apply_enum_statistics
    statement = "SUM(CASE WHEN #C# = #X# THEN 1 ELSE 0 END)"
    statistics_columns = []
    clazz.columns_hash.each do |name,c|
      enum_values = clazz.settings.enum_values_for(name)
      next if enum_values.blank?
      enum_values.each do |key, value|
        key = "'#{key}'" if [:string, :text].include? c.type
        @projections.push statement.gsub('#C#', quote_column_name(name)).gsub("#X#", key)
        @select_values.push [name, value]
      end
    end
  end

  def apply_number_statistics
    statistics_columns = []
    clazz.columns_hash.each do |name,c|
      if [:integer, :float, :decimal].include?(c.type) && !name.ends_with?('_id') &&
        clazz.settings.enum_values_for(name).nil? && clazz.settings.columns[:listing].include?(name)
        statistics_columns.push name
      end
    end
    @projections += statistics_columns.map do |column_name|
      quoted_column = "#{quoted_table_name}.#{quote_column_name(column_name)}"
      ['max', 'min', 'avg'].map do |calculation|
        @select_values.push [column_name, calculation]
        "#{calculation.upcase}(#{quoted_column})"
      end
    end.flatten
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
    unless params[:order][/[.\/]/]
      params[:order] = "#{quoted_table_name}.#{params[:order]}"
    end
    nulllasts = @generic.postgresql? ? ' NULLS LAST' : ''
    @items = @items.order(params[:order] + nulllasts)
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

  def apply_filters
    predication = nil
    @current_filter.each do |filter|
      clause = apply_filter filter
      if predication.nil?
        predication = clause
      else
        predication = if filter['grouping'] == 'or'
          predication.or(clause)
        else
          predication.and(clause)
        end
      end
    end
    @items = @items.where(predication)
    logger.info @items.to_sql
  end

  def apply_filter filter
    operators = {
      'null' => {:class => Arel::Nodes::Equality, :right => nil},
      'not_null' => {:class => Arel::Nodes::NotEqual, :right => nil},
      'is_true' => {:class => Arel::Nodes::Equality, :right => true},
      'is_false' => {:class => Arel::Nodes::Equality, :right => false},
      '!=' => {:class => Arel::Nodes::NotEqual},
      '=' => {:class => Arel::Nodes::Equality},
      '>' => {:class => Arel::Nodes::GreaterThan},
      '>=' => {:class => Arel::Nodes::GreaterThanOrEqual},
      '<' => {:class => Arel::Nodes::LessThan},
      '<=' => {:class => Arel::Nodes::LessThanOrEqual},
      'IN' => {:class => Arel::Nodes::In, :right => filter['operand'].to_s.split(',').map(&:strip)},
      'is' => {:class => Arel::Nodes::Equality},
      'blank' => {:specific => 'blank'},
      'present' => {:specific => 'present'}
    }
    type = clazz.columns_hash[filter['column']].type
    operators.merge! datetime_operators if [:date, :datetime].index(type)
    operators.merge! string_operators if [:string].index(type)
    column = clazz.arel_table[filter['column']]
    operation = operators[filter['operator']]
    if operation[:named_function]
      column = Arel::Nodes::NamedFunction.new(operation[:named_function], [column])
    end
    return send("apply_filter_#{operation[:specific]}", column) if operation[:specific]
    operation[:class].new column, right_value(operation, filter['operand'])
  end

  def string_operators
    {
      'like' => {:class => Arel::Nodes::Matches, :replace_right => "%_%"},
      'not_like' => {:class => Arel::Nodes::DoesNotMatch, :replace_right => '%_%'},
      'starts_with' => {:class => Arel::Nodes::Matches, :replace_right => "_%"},
      'ends_with' => {:class => Arel::Nodes::Matches, :replace_right => "%_"},
      'not' => {:class => Arel::Nodes::NotEqual}
    }
  end

  def datetime_operators
    today = Date.today
    {
      'today' => {:class => Arel::Nodes::Equality, :right => today, :named_function => "DATE"},
      'yesterday' => {:class => Arel::Nodes::Equality, :right => 1.day.ago.to_date, :named_function => "DATE"},
      'this_week' => {:class => Arel::Nodes::Between, :right => Arel::Nodes::And.new([today.beginning_of_week, today.end_of_week])},
      'last_week' => {:class => Arel::Nodes::Between, :right => Arel::Nodes::And.new([1.week.ago.beginning_of_week, 1.week.ago.end_of_week])},
      'on' => {:class => Arel::Nodes::Equality, :named_function => "DATE", :right_function => 'to_date'},
      'not' => {:class => Arel::Nodes::NotEqual, :named_function => "DATE", :right_function => 'to_date'},
      'after' => {:class => Arel::Nodes::LessThan, :named_function => "DATE"},
      'before' => {:class => Arel::Nodes::GreaterThan, :named_function => "DATE"}
    }
  end

  def apply_filter_blank column
    column.eq(nil).or(column.eq(''))
  end

  def apply_filter_present column
    column.not_eq(nil).and(column.not_eq(''))
  end

  def right_value operation, value
    return operation[:right] if operation.has_key?(:right)
    return operation[:replace_right].gsub('_', value) if operation.has_key?(:replace_right)
    return value.to_date if operation[:right_function] == 'to_date'
    return value
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
    case params[:then_redirect]
    when /edit/
      edit_resource_path(params[:table], @item)
    when /create/
      new_resource_path(params[:table])
    else
      resource_path(params[:table], @item)
    end
  end

  def update_from_import pk, columns, data
    data.map do |row|
      attrs = {}
      columns.each_with_index do |name, index|
        attrs[name] = row[index]
      end
      id = attrs.delete pk
      clazz.find(id).update_attributes! attrs
      id
    end
  end

end