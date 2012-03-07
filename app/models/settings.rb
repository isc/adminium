module Settings

  def settings
    @settings ||= Base.new(self)
    return @settings
  end

  class Global

    DEFAULTS = {:per_page => 25, :date_format => :long, :datetime_format => :long}

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



    attr_accessor :filters


    def initialize(clazz)
      @clazz = clazz
      load
    end

    def load
      @globals = Global.new @clazz.account_id
      value = REDIS.get settings_key
      if value.nil?
        self.columns = @clazz.columns.map(&:name)
      else
        datas = JSON.parse(value).symbolize_keys!
        @columns = datas[:columns]
        @filters = datas[:filters]
        @per_page = datas[:per_page] || @globals[:per_page]
      end
      @filters ||= []
    end

    def save
      settings = {:columns => @columns, :filters => @filters}
      settings.merge :per_page => @per_page if @globals[:per_page] != @per_page
      REDIS.set settings_key, settings.to_json
    end

    def settings_key
      "account:#{@clazz.account_id}:settings:#{@clazz.original_name}"
    end

    def columns= columns
      @columns = columns.map do |column|
        {'name' => column}
      end
    end

    def per_page= per_page
      @per_page = per_page.to_i
    end

    def per_page
      @per_page ||= @globals.per_page
    end

    def column_names
      @columns.map do |column|
        column['name']
      end
    end


  end

end