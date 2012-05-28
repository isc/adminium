module Settings

  def settings
    @settings ||= Base.new(self)
  end

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

    def initialize clazz
      @clazz = clazz
      load
    end

    def load
      @globals = Global.new @clazz.adminium_account_id
      value = REDIS.get settings_key
      if value.nil?
        @columns, @enum_values, @validations = {}, [], []
      else
        datas = JSON.parse(value).symbolize_keys!
        @columns = datas[:columns].symbolize_keys!
        if datas[:filters].is_a?(Array)
          # to be removed in a few weeks, just in case
          @filters = {"last search" => datas[:filters]}
        else
          @filters = datas[:filters]
        end
        @default_order = datas[:default_order]
        @per_page = datas[:per_page] || @globals.per_page
        @enum_values = datas[:enum_values] || []
        @validations = datas[:validations] || []
        @label_column = datas[:label_column]
        @export_skip_header = datas[:export_skip_header]
        @export_col_sep = datas[:export_col_sep]
      end
      @default_order ||= "#{@clazz.primary_key} desc" if @clazz.primary_key
      set_missing_columns_conf
      @filters ||= {}
    end

    def save
      settings = {columns: @columns, filters: @filters, validations: @validations,
        default_order: @default_order, enum_values: @enum_values, label_column: @label_column,
        export_col_sep: @export_col_sep, export_skip_header: @export_skip_header}
      settings.merge! per_page: @per_page if @globals.per_page != @per_page
      REDIS.set settings_key, settings.to_json
    end

    def settings_key
      "account:#{@clazz.adminium_account_id}:settings:#{@clazz.original_name}"
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

    def columns_options type, opts = {}
      return @columns[type] if opts[:only_checked]
      case type
      when :search
        column_names = searchable_column_names
      when :serialized
        column_names = string_or_text_column_names
      else
        column_names = @clazz.column_names
      end
      non_checked = (column_names - @columns[type]).map {|n|[n, false]}
      checked = @columns[type].map {|n|[n, true]}
      checked + non_checked
    end

    def string_column_names
      @clazz.columns.find_all{|c|c.type == :string}.map(&:name)
    end

    def column_type(column_name)
      @clazz.columns.detect{|c|c.name == column_name}.try(:type)
    end

    def is_string_column?(column_name)
      column_type(column_name) == :string
    end

    def is_number_column?(column_name)
      [:integer, :decimal].include? column_type(column_name)
    end

    def string_or_text_column_names
      find_all_columns_for_types(:string, :text).map(&:name)
    end

    def find_all_columns_for_types *types
      @clazz.columns.find_all{|c| types.include? c.type}
    end

    def searchable_column_names
      find_all_columns_for_types(:string, :text, :integer, :decimal).map(&:name)
    end

    def set_missing_columns_conf
      [:listing, :show, :form, :search, :serialized, :export].each do |type|
        if @columns[type]
          @columns[type].delete_if {|name| !name.include?('.') && !(@clazz.column_names.include? name) }
        else
          @columns[type] =
          {listing: @clazz.column_names, show: @clazz.column_names,
            form: (@clazz.column_names - %w(created_at updated_at id)),
            export: @clazz.column_names,
            search: searchable_column_names, serialized: []}[type]
        end
      end
    end

    def enum_values_for column_name
      return unless enum_value = @enum_values.detect {|enum_value| enum_value['column_name'] == column_name}
      Hash[enum_value['values'].split("\n").map {|val|val.split(':').map(&:strip).reverse}]
    end

    def possible_enum_columns
      @clazz.columns.find_all {|c| !c.primary && ![:date, :datetime].include?(c.type)}
    end

  end

end
