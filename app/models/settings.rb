module Settings

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

    attr_accessor :filters, :default_order, :enum_values, :validations, :label_column, :export_col_sep, :export_skip_header

    def initialize generic, table
      @generic, @table = generic, table
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
      @default_order ||= "#{primary_key} desc" if primary_key.any?
      set_missing_columns_conf
      @filters ||= {}
    end
    
    def primary_key
      schema.find_all {|c, info| info[:primary_key]}
    end
    
    def schema
      @schema ||= @generic.db.schema(@table)
    end
    
    def column_names
      schema.map {|c, _| c}
    end
    
    def save
      settings = {columns: @columns, column:@column, filters: @filters, validations: @validations,
        default_order: @default_order, enum_values: @enum_values, label_column: @label_column,
        export_col_sep: @export_col_sep, export_skip_header: @export_skip_header}
      settings.merge! per_page: @per_page if @globals.per_page != @per_page
      REDIS.set settings_key, settings.to_json
    end

    def settings_key
      "account:#{@generic.account_id}:settings:#{@table}"
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
      hidden = options.delete :hide
      @columns[:listing].delete name if hidden
      if options[:serialized]
        @columns[:serialized].push(name)
      else
        @columns[:serialized].delete(name)
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

    def column_type(column_name)
      info = schema.detect{|c, _| c == column_name}.try(:second)
      info[:type] if info
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
          @columns[type].delete_if {|name| !association_column?(name) && !(column_names.include? name) }
        else
          @columns[type] =
          {listing: column_names, show: column_names,
            form: (column_names - %w(created_at updated_at id)),
            export: column_names,
            search: searchable_column_names, serialized: []}[type]
        end
      end
    end
    
    def association_column? name
      name.include?('.') || name.starts_with?('has_many/')
    end

    def enum_values_for column_name
      return unless enum_value = @enum_values.detect {|enum_value| enum_value['column_name'] == column_name}
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

  end

end
