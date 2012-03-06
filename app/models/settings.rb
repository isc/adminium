module Settings

  def settings
    @settings ||= Base.new(self)
  end

  class Global
    
    DEFAULT_PER_PAGE = 25

    def self.load
      value = REDIS.get "global_settings"
      @globals = value.nil? ? {} : JSON.parse(value).symbolize_keys!
      @globals.reverse_merge! :per_page => DEFAULT_PER_PAGE, :date_format => :long, :datetime_format => :long
    end

    def self.update settings
      REDIS.set "global_settings", settings.to_json
    end

    def self.method_missing name, *args, &block
      load
      return @globals[name] unless @globals[name].nil?
      super
    end

  end

  class Base

    attr_accessor :filters, :default_order

    def initialize clazz
      @clazz = clazz
      load
    end

    def load
      @globals = Global.load
      value = REDIS.get settings_key
      if value.nil?
        @columns = {:listing => @clazz.column_names, :form => @clazz.column_names, :show => @clazz.column_names}
      else
        datas = JSON.parse(value).symbolize_keys!
        @columns = datas[:columns].symbolize_keys!
        @filters = datas[:filters]
        @default_order = datas[:default_order] || @clazz.column_names.first
        @per_page = datas[:per_page] || @globals[:per_page]
      end
      @filters ||= []
    end

    def save
      settings = {:columns => @columns, :filters => @filters, :default_order => @default_order}
      settings.merge :per_page => @per_page if @globals[:per_page] != @per_page
      REDIS.set settings_key, settings.to_json
    end
    
    def settings_key
      "account:#{@clazz.account_id}:#{@clazz.original_name}:settings"
    end

    def per_page= per_page
      @per_page = per_page.to_i
    end

    def per_page
      @per_page ||= @globals[:per_page]
    end

    def columns type = nil
      type ? @columns[type] : @columns
    end

  end

end