module Settings

  def settings
    @settings ||= Base.new(self)
  end

  class Global

    DEFAULTS = {per_page: 25, date_format: :long, datetime_format: :long}

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

    attr_accessor :filters, :default_order, :enum_values, :validations, :label_column

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
        @filters = datas[:filters]
        @default_order = datas[:default_order]
        @per_page = datas[:per_page] || @globals.per_page
        @enum_values = datas[:enum_values] || []
        @validations = datas[:validations] || []
        @label_column = datas[:label_column]
      end
      @default_order ||= "#{@clazz.primary_key} desc"
      set_missing_columns_conf
      @filters ||= []
    end

    def save
      settings = {columns: @columns, filters: @filters, validations: @validations,
        default_order: @default_order, enum_values: @enum_values, label_column: @label_column}
      settings.merge! per_page: @per_page if @globals.per_page != @per_page
      REDIS.set settings_key, settings.to_json
    end

    def settings_key
      "account:#{@clazz.adminium_account_id}:settings:#{@clazz.original_name}"
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
        column_names = string_column_names
      when :serialized
        column_names = string_or_text_column_names
      else
        column_names = @clazz.column_names
      end
      options = column_names.map {|name| [name, @columns[type].include?(name)]}
      checked, non_checked = options.partition {|name, checked| checked }
      checked + non_checked
    end

    def string_column_names
      @clazz.columns.find_all{|c|c.type == :string}.map(&:name)
    end

    def string_or_text_column_names
      @clazz.columns.find_all{|c|[:string, :text].include? c.type}.map(&:name)
    end

    def set_missing_columns_conf
      [:listing, :show, :form, :form, :search, :serialized].each do |type|
        if @columns[type]
          @columns[type].delete_if {|name| !@clazz.column_names.include? name }
        else
          @columns[type] =
          {listing: @clazz.column_names, show: @clazz.column_names,
            form: (@clazz.column_names - %w(created_at updated_at id)),
            search: string_column_names, serialized: []}[type]
        end
      end
    end

    def enum_values_for column_name
      return unless enum_value = @enum_values.detect {|enum_value| enum_value['column_name'] == column_name}
      Hash[enum_value['values'].split("\n").map {|val|val.split(':').map(&:strip).reverse}]
    end

    def possible_enum_columns
      @clazz.columns.find_all {|c| !c.primary}
    end

  end

end
