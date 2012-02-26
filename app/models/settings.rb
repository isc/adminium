module Settings

  def settings
    @settings ||= Base.new(self)
    return @settings
  end

  class Global
    
    DEFAULT_PER_PAGE = 25

    def self.load
      value = REDIS.get "global_settings"
      unless value.nil?
        @globals = JSON.parse(value).symbolize_keys!
      end
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

    

    attr_accessor :filters


    def initialize(clazz)
      @clazz = clazz
      load
    end

    def load
      @globals = Global.load
      value = REDIS.get "#{@clazz.original_name}:settings"
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
      REDIS.set "#{@clazz.original_name}:settings", settings.to_json
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
      @per_page ||= @globals[:per_page]
    end

    def column_names
      @columns.map do |column|
        column['name']
      end
    end


  end

end