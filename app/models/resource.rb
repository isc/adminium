module Resource

  class Global

    DEFAULTS = {per_page: 25, date_format: :long, datetime_format: :long, export_col_sep: ',', export_skip_header: false}

    def initialize account_id
      @account_id = account_id
      value = REDIS.get global_key_settings
      @globals = value.nil? ? {} : JSON.parse(value)
      @globals.reverse_merge!(DEFAULTS).symbolize_keys!
    end

    def global_key_settings
      "account:#{@account_id}:global_settings"
    end

    def update settings
      REDIS.set global_key_settings, settings.to_json
    end

    def method_missing name, *args, &block
      return @globals[name] if @globals.has_key? name
      super
    end

  end

  class Base

    VALIDATES_PRESENCE_OF = 'validates_presence_of'
    VALIDATES_UNIQUENESS_OF = 'validates_uniqueness_of'
    VALIDATORS = [VALIDATES_PRESENCE_OF, VALIDATES_UNIQUENESS_OF]

    attr_accessor :filters, :default_order, :enum_values, :validations, :label_column, :export_col_sep, :export_skip_header, :table

    def initialize generic, table
      @generic, @table = generic, table.to_sym
      load
    end

    def load
      @globals = Global.new @generic.account_id
      value = REDIS.get settings_key
      if value.nil?
        @column, @columns, @enum_values, @validations = {}, {}, [], []
      else
        datas = JSON.parse(value).symbolize_keys!
        @columns = datas[:columns].symbolize_keys!
        if datas[:filters].is_a?(Array)
          # to be removed in a few weeks, just in case
          @filters = {"last search" => datas[:filters]}
        else
          @filters = datas[:filters]
        end
        @column = datas[:column] || {}
        @default_order = datas[:default_order]
        @per_page = datas[:per_page] || @globals.per_page
        @enum_values = datas[:enum_values] || []
        @validations = datas[:validations] || []
        @label_column = datas[:label_column]
        @export_skip_header = datas[:export_skip_header]
        @export_col_sep = datas[:export_col_sep]
      end
      @default_order ||= default_primary_keys_order
      set_missing_columns_conf
      @filters ||= {}
    end
    
    def default_primary_keys_order
      primary_keys.map {|key| "#{key} desc"}.join ',' if primary_keys.any?
    end
    
    def default_order_column
      default_order.split(' ').first if default_order
    end
    
    def default_order_direction
      default_order.split(' ').second if default_order
    end
    
    def primary_keys
      primary_keys = schema.find_all {|c, info| info[:primary_key]}.map(&:first)
      return primary_keys if primary_keys.any?
      [:id, :Id, :uuid].each do |name|
        return [name] if column_names.include? name
      end
      primary_keys = column_names.find_all {|c| c.to_s.ends_with? '_id'}
      primary_keys = column_names.find_all {|c| c.to_s =~ /\wId$/} if primary_keys.empty?
      return primary_keys if primary_keys.size > 1
      []
    end
    
    def primary_key
      raise "Asking for a single primary_key on a composite primary key table" if primary_keys.size > 1
      primary_keys.first
    end
    
    def primary_key_value item
      return unless item && primary_keys.any?
      primary_keys.map do |name|
        item[name]
      end.join(',')
    end
    
    def primary_key_values_hash primary_key_value
      values = primary_key_value.is_a?(String) ? primary_key_value.split(',') : [primary_key_value]
      Hash[primary_keys.map {|key| [key, values.shift] }]
    end
    
    def composite_primary_key?
      primary_keys.size > 1
    end
    
    def schema
      @generic.schema(@table)
    end
    
    def schema_hash
      @schema_hash||= Hash[schema]
    end
    
    def query
      @generic.db[@table]
    end
    
    def index_exists? name
      indexes.values.detect {|info| info[:columns].include? name}
    end
    
    def indexes
      @indexes ||= @generic.db.indexes(@table)
    end
    
    def column_names
      schema.map {|c, _| c}
    end
    
    def save
      settings = {columns: @columns, column: @column, filters: @filters, validations: @validations,
        default_order: @default_order, enum_values: @enum_values, label_column: @label_column,
        export_col_sep: @export_col_sep, export_skip_header: @export_skip_header}
      settings.merge! per_page: @per_page if @globals.per_page != @per_page
      REDIS.set settings_key, settings.to_json
    end

    def settings_key
      "account:#{@generic.account_id}:settings:#@table"
    end

    def csv_options= options
      @export_skip_header = options.has_key?(:skip_header)
      @export_col_sep = options[:col_sep] if options.has_key? :col_sep
    end

    def export_col_sep
      @export_col_sep
    end

    def per_page= per_page
      @per_page = per_page.to_i
    end

    def per_page
      @per_page ||= @globals.per_page
    end

    def columns type = nil
      type ? @columns[type] : @columns
    end

    def column_options name
      @column[name.to_s] || {}
    end

    def update_column_options name, options
      hidden, view = [options.delete(:hide), options.delete(:view)]
      @columns[view.to_sym].delete name if hidden
      if options[:serialized]
        @columns[:serialized].push name
      else
        @columns[:serialized].delete name
      end
      @columns[:serialized].uniq!
      @column[name.to_s] = options
      save
    end
    
    def update_enum_values params
      return if params[:enum_data].nil?
      @enum_values.delete_if {|enums| enums['column_name'] == params[:column]}
      values = {}
      params[:enum_data].values.each do |value|
        db_value = value.delete 'value'
        values[db_value] = value if db_value.present? && value['label'].present?
      end
      @enum_values.push({'column_name' => params[:column], 'values' => values}) if values.present?
      save
    end

    def columns_options type, opts = {}
      return @columns[type] if opts[:only_checked]
      case type
      when :search
        names = searchable_column_names
      when :serialized
        names = string_or_text_column_names
      else
        names = column_names
      end
      non_checked = (names - @columns[type]).map {|n|[n, false]}
      checked = @columns[type].map {|n|[n, true]}
      checked + non_checked
    end

    def string_column_names
      schema.find_all{|c, info|info[:type] == :string}.map(&:first)
    end

    def column_type column_name
      info = column_info column_name
      info[:type] if info
    end
    
    def column_info column_name
      schema.detect{|c, _| c == column_name}.try(:second)
    end

    def is_number_column?(column_name)
      [:integer, :decimal].include? column_type(column_name)
    end
    
    def is_text_column?(column_name)
      [:string, :text].include? column_type(column_name)
    end
    
    def is_date_column? column_name
      [:datetime, :date, :timestamp].include? column_type(column_name)
    end
    
    def string_or_text_column_names
      find_all_columns_for_types(:string, :text).map(&:first)
    end

    def searchable_column_names
      find_all_columns_for_types(:string, :text, :integer, :decimal).map(&:first)
    end

    def find_all_columns_for_types *types
      schema.find_all{|_, info| types.include? info[:type]}
    end

    def set_missing_columns_conf
      [:listing, :show, :form, :search, :serialized, :export].each do |type|
        if @columns[type]
          @columns[type] = @columns[type].map(&:to_sym)
          @columns[type].delete_if {|name| !association_column?(name) && !(column_names.include? name) }
        else
          @columns[type] =
          {listing: column_names, show: column_names,
            form: default_form_columns_conf, export: column_names,
            search: searchable_column_names, serialized: []}[type]
        end
      end
    end
    
    def default_form_columns_conf
      res = column_names - [:created_at, :updated_at]
      primary_keys.each do |primary_key|
        res.delete primary_key if schema_hash[primary_key][:default] || schema_hash[primary_key][:auto_increment]
      end
      res
    end
    
    def foreign_key? name
      return associations[:belongs_to].values.find {|assoc| assoc[:foreign_key] == name }
    end
    
    def db_foreign_key? name
      table_fks = @generic.foreign_keys[@table]
      return if table_fks.nil?
      table_fks.detect {|h| h[:column] == name}
    end
    
    def human_name
      table.to_s.humanize.singularize
    end
    
    def association_column? name
      name.to_s.include?('.') || name.to_s.starts_with?('has_many/')
    end

    def enum_values_for column_name
      return unless enum_value = @enum_values.detect {|enum_value| enum_value['column_name'] == column_name.to_s}
      enum_value['values']
    end

    def possible_enum_columns
      schema.find_all {|_, info| possible_enum_column info }
    end

    def possible_enum_column info
      !info[:primary_key] && ![:date, :datetime, :text, :float].include?(info[:type])
    end

    def possible_serializable_column info
      [:text, :string].include? info[:type]
    end

    def adminium_column_options
      res = {}
      column_names.each do |column|
        res[column] = column_options(column) || {is_enum: false}
        enum = enum_values_for column
        res[column].merge! is_enum: true, values: enum if enum
        res[column].merge! displayed_column_name: column_display_name(column)
      end
      res
    end

    def column_display_name key
      value = column_options(key)['rename']
      if value.present?
        value
      else
        key = key.to_s
        if key.starts_with? 'has_many/'
          key = key.gsub 'has_many/', ''
          "#{key.humanize} count"
        else
          key.humanize
        end
      end
    end
    
    def required_column? name
      return true if primary_keys.include? name
      return true if schema_hash[name][:allow_null] == false
      validations.detect {|val| val['validator'] == VALIDATES_PRESENCE_OF && val['column_name'] == name.to_s}
    end
    
    def item_label item
      return unless item
      res = item[label_column.to_sym] if label_column
      res || "#{human_name} ##{primary_key_value item}"
    end
    
    def pk_filter primary_key_value
      q = query
      values = primary_key_value.is_a?(String) ? primary_key_value.split(',') : [primary_key_value]
      primary_keys.each do |key|
        q = q.where(key => values.shift)
      end
      q
    end
    
    def validations_check primary_key_value, updated_values
      validations.each do |validation|
        next unless value = updated_values.detect {|k, _| k.value == validation['column_name']}.try(:second)
        case validation['validator']
        when VALIDATES_PRESENCE_OF
          if value.blank?
            raise ValidationError.new "<b>#{column_display_name validation['column_name'].to_sym}</b> can't be blank."
          end
        when VALIDATES_UNIQUENESS_OF
          unless pk_filter(primary_key_value).invert.where(validation['column_name'].to_sym => value).empty?
            raise ValidationError.new "<b>#{value}</b> has already been taken."
          end
        end
      end
    end
    
    def update_item primary_key_value, updated_values
      updated_values = typecasted_values updated_values
      magic_timestamps updated_values, false
      validations_check primary_key_value, updated_values
      pk_filter(primary_key_value).update updated_values
    end
    
    def update_multiple_items ids, updated_values
      updated_values.reject!{|k,v|v.blank?}
      updated_values = typecasted_values updated_values
      magic_timestamps updated_values, false
      # FIXME doesn't work with composite primary keys
      query.where(primary_key => ids).update(updated_values)
    end
    
    def find primary_key_value
      find_by_primary_key(primary_key_value) || (raise RecordNotFound)
    end
    
    def find_by_primary_key primary_key_value
      pk_filter(primary_key_value).first
    end
    
    def delete primary_key_value
      pk_filter(primary_key_value).delete
    end
    
    def typecast_value column, value
      return value unless (col_schema = schema_hash[column])
      value = nil if '' == value && ![:string, :blob].include?(col_schema[:type])
      raise(Sequel::InvalidValue, "nil/NULL is not allowed for the #{column} column") if value.nil? && !col_schema[:allow_null]
      @generic.db.typecast_value col_schema[:type], value
    end
    
    def typecasted_values values
      values.each {|key, value| values[key] = typecast_value key.to_sym, value}
      Hash[values.map {|k, v| [Sequel.identifier(k), v]}]
    end
    
    def insert values
      values = typecasted_values values
      magic_timestamps values, true
      query.insert values
    end
    
    def magic_timestamps values, creation
      now = Time.now.utc
      columns = [:updated_at, :updated_on]
      columns += [:created_at, :created_on] if creation
      columns.each do |column|
        next if values.detect {|k,_|k.value.to_sym == column}
        if schema_hash[column] && [:timestamp, :date, :datetime].include?(schema_hash[column][:type])
          values[Sequel.identifier column] = now
        end
      end
    end
    
    def associations
      @generic.associations[@table]
    end
    
    def assoc_query item, name
      assoc = associations[:has_many][name]
      @generic.db[name].where(assoc[:foreign_key] => item[assoc[:primary_key]])
    end
    
    def has_many_count item, assoc_name
      assoc_query(item, assoc_name).count
    end
    
    def fetch_associated_items item, assoc_name, limit
      assoc_query(item, assoc_name).limit(limit)
    end
    
  end
  
  class RecordNotFound < StandardError
  end
  class ValidationError < StandardError
  end
  
end
