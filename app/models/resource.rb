module Resource
  class Global
    DEFAULTS = {per_page: 25, date_format: :long, datetime_format: :long, export_col_sep: ',', export_skip_header: false}.freeze

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
      return @globals[name] if @globals.key? name
      super
    end
  end

  class Base
    VALIDATES_PRESENCE_OF = 'validates_presence_of'.freeze
    VALIDATES_UNIQUENESS_OF = 'validates_uniqueness_of'.freeze
    VALIDATORS = [VALIDATES_PRESENCE_OF, VALIDATES_UNIQUENESS_OF].freeze

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
        @filters = datas[:filters]
        @column = datas[:column] || {}
        @default_order = datas[:default_order] if datas[:default_order].present? && column_names.include?(datas[:default_order].to_s.split(' ').first.to_sym)
        @per_page = datas[:per_page] || @globals.per_page
        @enum_values = datas[:enum_values] || []
        @validations = datas[:validations] || []
        @label_column = datas[:label_column] if column_names.include? datas[:label_column].try(:to_sym)
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
      default_order&.split(' ')&.first
    end

    def default_order_direction
      default_order&.split(' ')&.second
    end

    def primary_keys
      primary_keys = schema.find_all {|_, info| info[:primary_key]}.map(&:first)
      return primary_keys if primary_keys.any?
      %i(id Id uuid).each do |name|
        return [name] if column_names.include? name
      end
      primary_keys = column_names.find_all {|c| c.to_s.ends_with? '_id'}
      primary_keys = column_names.find_all {|c| c.to_s =~ /\wId$/} if primary_keys.empty?
      return primary_keys if primary_keys.many?
      []
    end

    def primary_key
      raise 'Asking for a single primary_key on a composite primary key table' if composite_primary_key?
      primary_keys.first
    end

    def primary_key_value item
      return unless item && primary_keys.any?
      primary_keys.map do |name|
        item[name]
      end.compact.join(',').presence
    end

    def primary_key_values_hash primary_key_value
      values = primary_key_value.is_a?(String) ? primary_key_value.split(',') : [primary_key_value]
      Hash[primary_keys.map {|key| [key, values.shift] }]
    end

    def composite_primary_key?
      primary_keys.many?
    end

    def schema
      @generic.schema(@table)
    end

    def schema_hash
      @schema_hash ||= Hash[schema]
    end

    def query
      @generic.db[Sequel.identifier @table]
    end

    def index_exists? name
      indexes.values.detect {|info| info[:columns].include? name}
    end

    def indexes
      @indexes ||= @generic.indexes @table
    end

    def column_names
      schema.map {|c, _| c}
    end

    def save
      settings = {
        columns: @columns, column: @column, validations: @validations,
        default_order: @default_order, enum_values: @enum_values, label_column: @label_column,
        export_col_sep: @export_col_sep, export_skip_header: @export_skip_header
      }
      settings[:per_page] = @per_page if @globals.per_page != @per_page
      REDIS.set settings_key, settings.to_json
    end

    def settings_key
      "account:#{@generic.account_id}:settings:#{@table}"
    end

    def csv_options= options
      @export_skip_header = options.key?(:skip_header)
      @export_col_sep = options[:col_sep] if options.key? :col_sep
    end

    def per_page= per_page
      @per_page = [per_page.to_i, 25].max
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
      hidden, view = options.values_at :hide, :view
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

    def update_enum_values column, enum_data
      return if enum_data.nil?
      @enum_values.delete_if {|enums| enums['column_name'] == column}
      values = {}
      enum_data.each do |value|
        db_value = value.delete 'value'
        values[db_value] = value if db_value.present? && value['label'].present?
      end
      @enum_values.push 'column_name' => column, 'values' => values if values.present?
      save
    end

    def columns_options type, opts = {}
      return @columns[type] if opts[:only_checked]
      names = case type
              when :search
                searchable_column_names
              when :serialized
                string_or_text_column_names
              else
                column_names
              end
      non_checked = (names - @columns[type]).map {|n| [n, false]}
      checked = @columns[type].map {|n| [n, true]}
      checked + non_checked
    end

    def column_type column_name
      info = column_info column_name
      info[:type] || info[:db_type] if info
    end

    def column_info column_name
      @column_info ||= {}
      @column_info[column_name] ||= schema.detect {|c, _| c == column_name}&.second
    end

    def number_column? column_name
      %i(integer float decimal).include? column_type(column_name)
    end

    def boolean_column? column_name
      column_type(column_name) == :boolean
    end

    def text_column? column_name
      [:string, :text, 'name'].include? column_type(column_name)
    end

    def array_column? column_name
      column_type(column_name).to_s['_array']
    end

    def date_column? column_name
      %i(datetime date timestamp).include? column_type(column_name)
    end

    def uuid_column? column_name
      column_info(column_name)[:db_type] == 'uuid'
    end

    def pie_chart_column? name
      enum_values_for(name) || boolean_column?(name) || foreign_key?(name)
    end

    def stat_chart_column? name
      number_column?(name) && !name.to_s.ends_with?('_id') && enum_values_for(name).nil? && !primary_keys.include?(name)
    end

    def binary_column? name
      binary_column_names.include? name
    end

    def stat_chart_column_names
      column_names.find_all {|n| stat_chart_column? n}
    end

    def pie_chart_column_names
      column_names.find_all {|n| pie_chart_column? n}
    end

    def binary_column_names
      schema.find_all {|_, info| info[:type] == :blob}.map(&:first)
    end

    def string_column_names
      schema.find_all {|_, info| info[:type] == :string}.map(&:first)
    end

    def string_or_text_column_names
      find_all_columns_for_types(:string, :text).map(&:first)
    end

    def date_column_names
      find_all_columns_for_types(:datetime, :date, :timestamp).map(&:first)
    end

    def searchable_column_names
      find_all_columns_for_types(:string, :varchar_array, :text, :integer, :decimal, 'uuid', 'name').map(&:first)
    end

    def find_all_columns_for_types *types
      schema.find_all {|_, info| types.include?(info[:type] || info[:db_type])}
    end

    def set_missing_columns_conf
      %i(listing show form search serialized export).each do |type|
        if @columns[type]
          @columns[type].uniq!
          @columns[type].map!(&:to_sym)
          @columns[type].delete_if {|name| !valid_association_column?(name) && !(column_names.include? name) }
        else
          @columns[type] =
            {
              listing: default_columns_conf, show: default_columns_conf,
              form: default_form_columns_conf, export: default_columns_conf,
              search: searchable_column_names, serialized: []
            }[type]
        end
      end
    end

    def default_columns_conf
      res = column_names
      res.delete :datname if @table == :pg_stat_activity
      res
    end

    def default_form_columns_conf
      res = column_names - %i(created_at inserted_at updated_at)
      primary_keys.each do |primary_key|
        res.delete primary_key if schema_hash[primary_key][:default] || schema_hash[primary_key][:auto_increment]
      end
      res
    end

    def foreign_key? name
      belongs_to_associations.find {|assoc| assoc[:foreign_key] == name}
    end

    def db_foreign_key? name
      table_fks = @generic.foreign_keys[@table]
      table_fks&.detect {|h| h[:column] == name}
    end

    def foreign_key_array? name
      return unless name.to_s.ends_with?('_ids') && array_column?(name)
      referenced_table = name.to_s.gsub(/_ids$/, '').pluralize.to_sym
      return unless @generic.tables.include? referenced_table
      {referenced_table: referenced_table, table: table, primary_key: :id, foreign_key: name}
    end

    def human_name
      table.to_s.humanize.singularize
    end

    def valid_association_column? name
      if name.to_s.starts_with?('has_many/')
        find_has_many_association_for_key name
      elsif name['.']
        belongs_to_associations.any? {|assoc| assoc[:foreign_key] == name.to_s.split('.').first.to_sym}
      end
    end

    def enum_values_for column_name
      enum_value = @enum_values.detect {|value| value['column_name'] == column_name.to_s}
      enum_value && enum_value['values']
    end

    def possible_enum_columns
      schema.find_all {|_, info| possible_enum_column info}
    end

    def possible_enum_column info
      !info[:primary_key] && !%i(date datetime text float time).include?(info[:type])
    end

    def possible_serializable_column info
      %i(text string).include? info[:type]
    end

    def adminium_column_options
      res = {}
      column_names.each do |column|
        res[column] = column_options(column) || {is_enum: false}
        enum = enum_values_for column
        res[column].merge! is_enum: true, values: enum if enum
        res[column][:displayed_column_name] = column_display_name(column)
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
          assoc = find_has_many_association_for_key key
          res = "#{assoc[:table].to_s.humanize} count"
          if has_many_associations.many? {|other_assoc| other_assoc[:table] == assoc[:table]}
            res << " as #{assoc[:foreign_key].to_s.humanize}"
          end
          res
        else
          key.split('.').map(&:humanize).join(' > ')
        end
      end
    end

    def required_column? name
      return true if primary_keys.include? name
      return true if schema_hash[name][:allow_null] == false
      validations.detect {|val| val['validator'] == VALIDATES_PRESENCE_OF && val['column_name'] == name.to_s}
    end

    def default_value name
      schema_hash[name][:ruby_default]
    end

    def item_label item
      return unless item
      res = item[label_column.to_sym] if label_column
      res.presence || "#{human_name} ##{primary_key_value item}"
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
        value = updated_values.detect {|k, _| k.value == validation['column_name']}.try(:second)
        next unless value
        case validation['validator']
        when VALIDATES_PRESENCE_OF
          if value.blank?
            raise ValidationError, "<b>#{column_display_name validation['column_name'].to_sym}</b> can't be blank."
          end
        when VALIDATES_UNIQUENESS_OF
          unless pk_filter(primary_key_value).invert.where(validation['column_name'].to_sym => value).empty?
            raise ValidationError, "<b>#{value}</b> has already been taken."
          end
        end
      end
    end

    def update_item primary_key_value, updated_values
      updated_values = typecasted_values updated_values, false
      validations_check primary_key_value, updated_values
      pk_filter(primary_key_value).update updated_values
    end

    def update_multiple_items ids, updated_values
      updated_values.delete_if {|k, v| v.blank? && column_type(k.to_sym) != :string}
      updated_values = typecasted_values updated_values, false
      # FIXME: doesn't work with composite primary keys
      query.where(primary_key => ids).update(updated_values) unless updated_values.empty?
    end

    def find primary_key_value, fetch_binary_values: false
      find_by_primary_key(primary_key_value, fetch_binary_values) || (raise RecordNotFound)
    end

    def find_by_primary_key primary_key_value, fetch_binary_values = false
      if primary_key_value.is_a? Sequel::Postgres::PGArray
        keys = primary_key_value.to_a
        keys.map!(&:to_i) if column_type(primary_keys.first) == :integer
        query.where(primary_keys.first => keys)
          .select(*columns_to_select(fetch_binary_values)).to_a.sort_by {|r| primary_key_value.index(r[primary_keys.first])}
      else
        pk_filter(primary_key_value).select(*columns_to_select(fetch_binary_values)).first
      end
    end

    def delete primary_key_value
      pk_filter(primary_key_value).delete
    end

    def typecast_value column, value
      return value unless (col_schema = schema_hash[column])
      value = nil if value == '' && !%i(string blob).include?(col_schema[:type])
      raise Sequel::InvalidValue, "nil/NULL is not allowed for the #{column} column" if value.nil? && !col_schema[:allow_null]
      if col_schema[:type] == :hstore && !value.nil?
        2.times {value.shift} # remove dummy entry needed to be able to empty the hash
        return Sequel.hstore Hash[*value.delete_if {|k, _| k == '_'}]
      end
      if value && value.is_a?(String) && col_schema[:type].to_s['_array']
        begin
          value = JSON.parse value
        rescue JSON::ParserError => e
          raise Sequel::InvalidValue, "invalid value for array type: #{e.message}"
        end
      end
      value = value.find_all(&:presence) if value.is_a? Array
      if value.is_a?(String) && %i(datetime timestamp).include?(col_schema[:type])
        value = application_time_zone.parse value
      end
      @generic.db.typecast_value col_schema[:type], value
    end

    def typecasted_values values, creation
      magic_timestamps values, creation
      values.each {|key, value| values[key] = typecast_value key.to_sym, value}
      Hash[values.map {|k, v| [Sequel.identifier(k), v]}]
    end

    def insert values
      values = typecasted_values values, true
      query.insert values
    end

    def magic_timestamps values, creation
      now = application_time_zone.now
      columns = %i(updated_at updated_on)
      columns += %i(created_at inserted_at created_on) if creation
      columns.each do |column|
        next if values.detect {|k, _| k.to_sym == column}
        if schema_hash[column] && %i(timestamp date datetime).include?(schema_hash[column][:type])
          values[column] = now
        end
      end
    end

    def application_time_zone
      @application_time_zone ||= ActiveSupport::TimeZone.new @generic.account.application_time_zone
    end

    def belongs_to_association column
      @generic.associations.detect {|assoc| assoc[:table] == @table && assoc[:foreign_key] == column}
    end

    def belongs_to_associations
      @generic.associations.select {|assoc| assoc[:table] == @table}
    end

    def has_many_associations
      @generic.associations.select {|assoc| assoc[:referenced_table] == @table}
    end

    def find_has_many_association_for_key key
      _, table, foreign_key = key.to_s.split('/')
      has_many_associations.detect {|assoc| assoc[:foreign_key] == foreign_key&.to_sym && assoc[:table] == table.to_sym}
    end

    def assoc_query item, assoc
      @generic.db[assoc[:table]].where assoc_conditions(item, assoc)
    end

    def assoc_count item, assoc
      @generic.with_timeout { assoc_query(item, assoc).count }
    end

    def assoc_conditions item, assoc
      result = {assoc[:foreign_key] => item[assoc[:primary_key]]}
      result[assoc[:foreign_key].to_s.gsub(/_id$/, '_type').to_sym] = table.to_s.classify if assoc[:polymorphic]
      result
    end

    def count_with_timeout
      @generic.with_timeout { query.count }
    end

    def count_from_stats
      @generic.table_counts([@table])[@table.to_s]
    end

    def fetch_associated_items item, assoc, limit
      assoc_query(item, assoc).limit(limit)
    end

    def last_primary_key_value
      query.select(primary_key).order(primary_key).last.try(:[], primary_key) || 0
    end

    def raw_column_output item, key
      info = column_info(key)
      if info.try(:[], :type) == :time
        item[key].try :strftime, '%R'
      elsif info.try(:[], :type) == :datetime
        item[key].try :strftime, '%F %T'
      else
        item[key]
      end
    end

    def system_table?
      @generic.system_table? table
    end

    def columns_to_select fetch_binary_values
      column_names.map do |column|
        if binary_column?(column) && !fetch_binary_values
          Sequel.function(:octet_length, column).as(column)
        else
          Sequel.identifier(column)
        end
      end
    end
  end

  class RecordNotFound < StandardError
  end
  class ValidationError < StandardError
  end
end
